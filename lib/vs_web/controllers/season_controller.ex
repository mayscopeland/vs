defmodule VsWeb.SeasonController do
  use VsWeb, :controller

  alias Vs.{Leagues, Seasons, Teams, Players, Plugins}
  alias Vs.Plugins.Registry

  def new(conn, _params) do
    contest_types = Registry.list_available_contest_types()
    render(conn, :new, contest_types: contest_types, page_title: "Create a VS Season")
  end

  def create(conn, %{
        "league_name" => season_name,
        "contest_type" => contest_type_with_year,
        "team_count" => team_count
      }) do
    # Parse contest_type and year from the form value (e.g., "NBA_2025")
    {contest_type, season_year} = parse_contest_type_and_year(contest_type_with_year)

    # Get plugin config
    case Registry.get_plugin_config(contest_type, season_year) do
      {:ok, config} ->
        # Create league first (if it doesn't exist)
        {:ok, league} = Leagues.create_league(%{contest_type: contest_type})

        # Load players if not already loaded for this league
        unless Players.players_loaded_for_league?(league.id) do
          case Plugins.load_initial_data(contest_type, season_year, league.id) do
            {:ok, _count} ->
              :ok

            {:error, reason} ->
              conn
              |> put_flash(:error, "Failed to load player data: #{inspect(reason)}")
              |> redirect(to: ~p"/leagues/add")
              |> halt()
          end
        end

        {:ok, season} =
          Seasons.create_season(%{
            league_id: league.id,
            season_year: season_year,
            name: season_name
          })

        # Setup defaults from plugin config
        {:ok, season} = Seasons.setup_season_defaults(season, config)

        # Create teams with random place + mascot names
        team_count_int = String.to_integer(team_count)
        team_names = get_random_team_names(team_count_int)

        Enum.each(team_names, fn name ->
          scheme = Vs.Team.ColorSchemes.random()
          font_style = Vs.Team.FontStyles.random()

          Teams.create_team(%{
            season_id: season.id,
            name: name,
            color_scheme_id: scheme.id,
            font_style: font_style.id
          })
        end)

        # Redirect to initial season page for league
        conn
        |> put_flash(:info, "League created successfully!")
        |> redirect(to: ~p"/leagues/#{league.id}")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Plugin configuration not found for #{contest_type} #{season_year}")
        |> redirect(to: ~p"/leagues/add")
    end
  end

  def show(conn, %{"id" => season_id}) do
    season = Seasons.get_season!(season_id)
    teams = Teams.list_teams_for_season(season_id)

    render(conn, :show, season: season, teams: teams, page_title: season.name)
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

    places
    |> Enum.take(count)
    |> Enum.zip(Enum.take(mascots, count))
    |> Enum.map(fn {place, mascot} -> "#{place} #{mascot}" end)
  end
end
