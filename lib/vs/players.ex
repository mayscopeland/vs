defmodule Vs.Players do
  @moduledoc """
  The Players context - handles scorer/player management.
  """

  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{Scorer, RosterScorer, League}

  @doc """
  Returns all scorers/players that are not rostered in a specific league.

  This finds all scorers for the league's contest type and season that are not
  currently on any team's roster in the league.
  """
  def list_available_players(league_id) do
    league = Repo.get!(League, league_id) |> Repo.preload(:universe)

    # Get all scorer IDs that are rostered in this league
    rostered_scorer_ids =
      from(rs in RosterScorer,
        join: r in assoc(rs, :roster),
        join: t in assoc(r, :team),
        where: t.league_id == ^league_id,
        select: rs.scorer_id,
        distinct: true
      )
      |> Repo.all()

    # Get all scorers for this contest type that are not rostered
    Scorer
    |> where([s], s.contest_type == ^league.universe.contest_type)
    |> where([s], s.id not in ^rostered_scorer_ids)
    |> order_by([s], asc: s.name)
    |> Repo.all()
  end

  @doc """
  Gets a single scorer by ID.

  Raises `Ecto.NoResultsError` if the Scorer does not exist.
  """
  def get_scorer!(id) do
    Repo.get!(Scorer, id)
  end

  @doc """
  Checks if players have been loaded for a specific contest type and season.

  Returns true if at least one scorer exists for the contest type.
  """
  def players_loaded_for_contest?(contest_type, _season_year) do
    Scorer
    |> where([s], s.contest_type == ^contest_type)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> false
      _ -> true
    end
  end
end
