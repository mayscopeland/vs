defmodule VsWeb.LeagueController do
  use VsWeb, :controller

  alias Vs.{Leagues, Teams, Players, Plugins}
  alias Vs.Plugins.Registry

  def new(conn, _params) do
    contest_types = Registry.list_available_contest_types()
    render(conn, :new, contest_types: contest_types, page_title: "Create a VS League")
  end

  def create(conn, %{
        "league_name" => league_name,
        "contest_type" => contest_type_with_year,
        "team_count" => team_count
      }) do
    # Parse contest_type and year from the form value (e.g., "NBA_2025")
    {contest_type, season_year} = parse_contest_type_and_year(contest_type_with_year)

    # Get plugin config
    case Registry.get_plugin_config(contest_type, season_year) do
      {:ok, config} ->
        # Create universe first
        {:ok, universe} = Leagues.create_universe(%{contest_type: contest_type})

        # Load players if not already loaded for this universe
        unless Players.players_loaded_for_universe?(universe.id) do
          case Plugins.load_initial_data(contest_type, season_year, universe.id) do
            {:ok, _count} -> :ok
            {:error, reason} ->
              conn
              |> put_flash(:error, "Failed to load player data: #{inspect(reason)}")
              |> redirect(to: ~p"/leagues/add")
              |> halt()
          end
        end

        {:ok, league} =
          Leagues.create_league(%{
            universe_id: universe.id,
            season_year: season_year,
            name: league_name
          })

        # Setup defaults from plugin config
        {:ok, league} = Leagues.setup_league_defaults(league, config)

        # Create teams with random place + mascot names
        team_count_int = String.to_integer(team_count)
        team_names = get_random_team_names(team_count_int)

        Enum.each(team_names, fn name ->
          scheme = Vs.Team.ColorSchemes.random()
          Teams.create_team(%{league_id: league.id, name: name, color_scheme_id: scheme.id})
        end)

        # Redirect to league page
        conn
        |> put_flash(:info, "League created successfully!")
        |> redirect(to: ~p"/leagues/#{league.id}")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Plugin configuration not found for #{contest_type} #{season_year}")
        |> redirect(to: ~p"/leagues/add")
    end
  end

  def show(conn, %{"id" => league_id}) do
    league = Leagues.get_league!(league_id)
    teams = Teams.list_teams_for_league(league_id)

    render(conn, :show, league: league, teams: teams, page_title: league.name)
  end

  defp parse_contest_type_and_year(contest_type_with_year) do
    # Parse "NBA_2025" -> {"NBA", 2025}
    case String.split(contest_type_with_year, "_") do
      [contest_type, year_str] ->
        {contest_type, String.to_integer(year_str)}

      _ ->
        raise "Invalid contest_type format: #{contest_type_with_year}"
    end
  end

  defp get_random_team_names(count) do
    data_dir = Application.app_dir(:vs, "priv/static/data")
    mascots_file = Path.join(data_dir, "mascots.txt")
    places_file = Path.join(data_dir, "places.txt")

    mascots =
      mascots_file
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.shuffle()

    places =
      places_file
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.shuffle()

    generate_unique_team_names(places, mascots, count, MapSet.new(), [])
  end

  defp generate_unique_team_names(_places, _mascots, 0, _used, acc), do: Enum.reverse(acc)

  defp generate_unique_team_names(places, mascots, count, used, acc) do
    place = Enum.random(places)
    mascot = Enum.random(mascots)
    team_name = "#{place} #{mascot}"

    if MapSet.member?(used, team_name) do
      # If duplicate, try again
      generate_unique_team_names(places, mascots, count, used, acc)
    else
      new_used = MapSet.put(used, team_name)
      generate_unique_team_names(places, mascots, count - 1, new_used, [team_name | acc])
    end
  end
end
