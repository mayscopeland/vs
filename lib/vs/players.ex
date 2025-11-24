defmodule Vs.Players do
  @moduledoc """
  The Players context - handles scorer/player management.
  """

  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{Scorer, League, Observation}

  @doc """
  Returns all scorers/players that are not rostered in a specific league.

  This finds all scorers for the league's universe that are not
  currently on any team's roster in the league.
  """
  def list_available_players(league_id, opts \\ []) do
    league = Repo.get!(League, league_id) |> Repo.preload(:universe)
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 50)
    offset = (page - 1) * per_page

    # Get all scorer IDs that are rostered in this league
    rostered_scorer_ids =
      from(r in Vs.Roster,
        join: t in assoc(r, :team),
        where: t.league_id == ^league_id,
        select: r.slots
      )
      |> Repo.all()
      |> Enum.flat_map(&Map.values/1)
      |> Enum.uniq()

    # Base query for available scorers
    query =
      Scorer
      |> where([s], s.universe_id == ^league.universe.id)
      |> where([s], s.id not in ^rostered_scorer_ids)

    # Get total count
    total_count = Repo.aggregate(query, :count, :id)

    # Get paginated results
    players =
      query
      |> order_by([s], asc: s.name)
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {players, total_count}
  end

  @doc """
  Gets a single scorer by ID.

  Raises `Ecto.NoResultsError` if the Scorer does not exist.
  """
  def get_scorer!(id) do
    Repo.get!(Scorer, id)
  end

  @doc """
  Checks if players have been loaded for a specific universe.

  Returns true if at least one scorer exists for the universe.
  """
  def players_loaded_for_universe?(universe_id) do
    Scorer
    |> where([s], s.universe_id == ^universe_id)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> false
      _ -> true
    end
  end

  @doc """
  Gets aggregated stats for a list of players for a specific season.

  Returns a map of %{scorer_id => %{"PTS" => 123, "FGM" => 45, ...}}
  """
  def get_player_stats(player_ids, season_year) when is_list(player_ids) do
    # Query all observations for these players in this season
    observations =
      Observation
      |> where([o], o.scorer_id in ^player_ids)
      |> where([o], o.season_year == ^season_year)
      |> select([o], %{scorer_id: o.scorer_id, stats: o.stats})
      |> Repo.all()

    # Group by scorer_id and aggregate stats
    observations
    |> Enum.group_by(& &1.scorer_id)
    |> Enum.map(fn {scorer_id, obs_list} ->
      aggregated_stats =
        obs_list
        |> Enum.map(& &1.stats)
        |> Enum.reduce(%{}, fn stats, acc ->
          Map.merge(acc, stats, fn _k, v1, v2 -> v1 + v2 end)
        end)

      {scorer_id, aggregated_stats}
    end)
    |> Map.new()
  end

  def get_player_stats(_, _), do: %{}
end
