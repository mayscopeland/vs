defmodule Vs.Teams do
  @moduledoc """
  The Teams context - handles team, roster, and period management.
  """

  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{Team, Roster, Period, RosterPosition}

  @doc """
  Gets a single team by ID with managers and users preloaded.

  Raises `Ecto.NoResultsError` if the Team does not exist.
  """
  def get_team!(id) do
    Team
    |> Repo.get!(id)
    |> Repo.preload([:league, managers: :user])
  end

  @doc """
  Returns all teams for a league with managers and users preloaded.
  """
  def list_teams_for_league(league_id) do
    Team
    |> where([t], t.league_id == ^league_id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
    |> Repo.preload(managers: :user)
  end

  @doc """
  Creates a team.

  ## Examples

      iex> create_team(%{name: "Team Name", league_id: 1})
      {:ok, %Team{}}

      iex> create_team(%{name: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a team.

  ## Examples

      iex> update_team(team, %{field: new_value})
      {:ok, %Team{}}

      iex> update_team(team, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Determines the current active period for a league based on today's date.

  Returns the period that contains today's date, or the most recent period if none contains today.
  Returns nil if the league has no periods.
  """
  def current_period_for_league(league_id) do
    today = Date.utc_today()

    # Try to find a period that contains today's date
    period =
      Period
      |> where([p], p.league_id == ^league_id)
      |> where([p], p.start_date <= ^today and p.end_date >= ^today)
      |> order_by([p], asc: p.sequence)
      |> limit(1)
      |> Repo.one()

    # If no period contains today, get the most recent period by sequence
    case period do
      nil ->
        Period
        |> where([p], p.league_id == ^league_id)
        |> order_by([p], desc: p.sequence)
        |> limit(1)
        |> Repo.one()

      period ->
        period
    end
  end

  @doc """
  Gets or creates a roster for a team and period with scorers preloaded.

  Returns nil if the period doesn't exist.
  """
  def get_roster_for_team(team_id, period_id) when not is_nil(period_id) do
    case Repo.get_by(Roster, team_id: team_id, period_id: period_id) do
      nil ->
        # Create a new roster if it doesn't exist
        {:ok, roster} =
          %Roster{}
          |> Roster.changeset(%{team_id: team_id, period_id: period_id})
          |> Repo.insert()

        roster
        |> Repo.preload(roster_scorers: :scorer)

      roster ->
        roster
        |> Repo.preload(roster_scorers: :scorer)
    end
  end

  def get_roster_for_team(_team_id, nil), do: nil

  @doc """
  Builds a grouped roster structure for display.

  Takes roster positions from the league, the roster with scorers, and returns
  a structure grouped by position group with filled/unfilled slots.

  ## Returns

  A list of group maps:
  ```
  [
    %{
      group: "Starters",
      slots: [
        %{position: "PG", scorer: %Scorer{}, filled: true},
        %{position: "SG", scorer: nil, filled: false},
        ...
      ]
    },
    ...
  ]
  ```
  """
  def build_position_groups(roster_positions, roster, _league) do
    # Get scorers from roster if available
    scorers =
      case roster do
        nil -> []
        roster -> Enum.map(roster.roster_scorers, & &1.scorer)
      end

    # Group roster positions by group field
    grouped_positions =
      roster_positions
      |> Enum.group_by(& &1.group)
      |> Enum.sort_by(fn {_group, positions} ->
        positions |> Enum.map(& &1.sequence) |> Enum.min()
      end)

    # Build slots for each group
    Enum.map(grouped_positions, fn {group, positions} ->
      slots = build_slots_for_positions(positions, scorers)

      %{
        group: group,
        slots: slots
      }
    end)
  end

  defp build_slots_for_positions(positions, scorers) do
    {slots, _remaining_scorers} =
      positions
      |> Enum.sort_by(& &1.sequence)
      |> Enum.flat_map_reduce(scorers, fn position, acc_scorers ->
        # Create 'count' number of slots for this position
        slots_for_position =
          1..position.count
          |> Enum.map_reduce(acc_scorers, fn _idx, inner_scorers ->
            # Try to find a scorer that matches this position
            scorer = find_matching_scorer(position, inner_scorers)

            # Remove matched scorer from list to avoid double-assignment
            updated_scorers =
              if scorer, do: List.delete(inner_scorers, scorer), else: inner_scorers

            slot = %{
              position: position.position,
              sub_positions: position.sub_positions,
              scorer: scorer,
              filled: !is_nil(scorer),
              roster_position: position
            }

            {slot, updated_scorers}
          end)

        slots_for_position
      end)

    slots
  end

  defp find_matching_scorer(roster_position, scorers) do
    # Get valid positions for this slot
    valid_positions =
      if roster_position.sub_positions do
        String.split(roster_position.sub_positions, ",")
        |> Enum.map(&String.trim/1)
      else
        [roster_position.position]
      end

    # Find first scorer that matches any valid position and hasn't been assigned
    Enum.find(scorers, fn scorer ->
      scorer.position in valid_positions
    end)
  end

  @doc """
  Gets all roster positions for a league, ordered by sequence.
  """
  def list_roster_positions_for_league(league_id) do
    RosterPosition
    |> where([rp], rp.league_id == ^league_id)
    |> order_by([rp], asc: rp.sequence)
    |> Repo.all()
  end
end
