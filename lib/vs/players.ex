defmodule Vs.Players do
  @moduledoc """
  The Players context - handles scorer/player management.
  """

  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{Scorer, Season}

  @doc """
  Returns all scorers/players that are not rostered in a specific season.

  This finds all scorers for the season's league that are not
  currently on any team's roster in the season.
  """
  def list_available_players(season_id, opts \\ []) do
    season = Repo.get!(Season, season_id) |> Repo.preload(:league)
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 50)

    # Get all scorer IDs that are rostered in this season
    rostered_scorer_ids =
      from(r in Vs.Roster,
        join: t in assoc(r, :team),
        where: t.season_id == ^season_id,
        select: r.slots
      )
      |> Repo.all()
      |> Enum.reject(&is_nil/1)
      |> Enum.flat_map(&Map.values/1)
      |> Enum.uniq()

    # Base query for available scorers
    query =
      Scorer
      |> where([s], s.league_id == ^season.league.id)
      |> where([s], s.id not in ^rostered_scorer_ids)

    # Fetch ALL matching scorers
    all_players = Repo.all(query)

    # Get active scoring categories for formulas
    scoring_categories = Vs.Seasons.get_active_scoring_categories(season)
    stat_source = Keyword.get(opts, :stat_source)

    # Process players: extract stats, calculate derived stats, and populate struct
    processed_players =
      Enum.map(all_players, fn player ->
        # Get raw stats for the source
        raw_stats = Map.get(player.stats, to_string(stat_source), %{})

        # Calculate derived stats
        calculated_stats =
          scoring_categories
          |> Enum.reduce(raw_stats, fn category, acc ->
            if category.formula do
              val = Vs.Stats.Calculator.calculate(category.formula, raw_stats)
              Map.put(acc, category.name, val)
            else
              acc
            end
          end)

        # Update player struct with the calculated stats for this view
        %{player | stats: calculated_stats}
      end)

    # Sort options
    sort_by = Keyword.get(opts, :sort_by, "name")
    sort_dir = Keyword.get(opts, :sort_dir, "asc")

    # Sort in memory
    sorted_players =
      cond do
        sort_by == "name" ->
          if sort_dir == "desc" do
            Enum.sort_by(processed_players, & &1.name, :desc)
          else
            Enum.sort_by(processed_players, & &1.name, :asc)
          end

        sort_by == "rank" ->
          # Sort by rank for the current stat_source
          sorter = fn p ->
            case Map.get(p.rank, stat_source) do
              # Treat nil as very high rank (unranked players go to the end)
              nil -> 999_999
              val -> val
            end
          end

          if sort_dir == "asc" do
            Enum.sort_by(processed_players, sorter, :asc)
          else
            Enum.sort_by(processed_players, sorter, :desc)
          end

        true ->
          # Sort by stat category
          sorter = fn p ->
            case Map.get(p.stats, sort_by) do
              # Treat nil as very low value
              nil -> -999_999.0
              val -> val
            end
          end

          if sort_dir == "asc" do
            Enum.sort_by(processed_players, sorter, :asc)
          else
            Enum.sort_by(processed_players, sorter, :desc)
          end
      end

    # Paginate
    total_count = length(sorted_players)
    offset = (page - 1) * per_page
    paginated_players = Enum.slice(sorted_players, offset, per_page)

    {paginated_players, total_count}
  end

  @doc """
  Gets a single scorer by ID.

  Raises `Ecto.NoResultsError` if the Scorer does not exist.
  """
  def get_scorer!(id) do
    Repo.get!(Scorer, id)
  end

  @doc """
  Checks if players have been loaded for a specific league.

  Returns true if at least one scorer exists for the league.
  """
  def players_loaded_for_league?(league_id) do
    Scorer
    |> where([s], s.league_id == ^league_id)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> false
      _ -> true
    end
  end

  def list_players_for_league(league_id) do
    Scorer
    |> where([s], s.league_id == ^league_id)
    |> Repo.all()
  end

  @doc """
  Gets aggregated stats for a list of players for a specific stat source.

  The source can be a year string (e.g. "2025", "2024") or "projection".
  Returns a map of %{scorer_id => %{"PTS" => 123, "FGM" => 45, ...}}
  """
  def get_player_stats(player_ids, stat_source) when is_list(player_ids) do
    # Query scorers and extract the requested stat source from their stats map
    from(s in Scorer,
      where: s.id in ^player_ids,
      select: {s.id, s.stats}
    )
    |> Repo.all()
    |> Enum.map(fn {id, stats} ->
      # Get the stats for the requested source, defaulting to empty map if not found
      source_stats = Map.get(stats, to_string(stat_source), %{})
      {id, source_stats}
    end)
    |> Map.new()
  end

  def get_player_stats(_, _), do: %{}
end
