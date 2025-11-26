defmodule Vs.Teams do
  @moduledoc """
  The Teams context - handles team, roster, and period management.
  """

  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{Team, Roster, Period, Scorer}

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
  Returns an `%Ecto.Changeset{}` for tracking team changes.

  ## Examples

      iex> change_team(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team(%Team{} = team, attrs \\ %{}) do
    Team.changeset(team, attrs)
  end

  @doc """
  Returns all periods for a league ordered by sequence.
  """
  def list_periods_for_league(league_id) do
    Period
    |> where([p], p.league_id == ^league_id)
    |> order_by([p], asc: p.sequence)
    |> Repo.all()
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

      roster ->
        roster
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
    # Get all scorer IDs from roster slots
    {scorer_ids, slots_map} =
      case roster do
        nil ->
          {[], %{}}

        %Roster{slots: nil} ->
          {[], %{}}

        %Roster{slots: slots} ->
          # slots is expected to be %{"PG" => [id1], "C" => [id2, id3]}
          ids =
            slots
            |> Map.values()
            |> List.flatten()
            |> Enum.uniq()

          {ids, slots}
      end

    # Fetch scorers
    scorers =
      if Enum.empty?(scorer_ids) do
        %{}
      else
        Scorer
        |> where([s], s.id in ^scorer_ids)
        |> Repo.all()
        |> Map.new(fn s -> {s.id, s} end)
      end

    # Group roster positions by group field
    grouped_positions =
      roster_positions
      |> Enum.group_by(& &1.group)

    # Build slots for each group
    Enum.map(grouped_positions, fn {group, positions} ->
      slots = build_slots_for_positions(positions, slots_map, scorers)

      %{
        group: group,
        slots: slots
      }
    end)
  end

  defp build_slots_for_positions(positions, slots_map, scorers_map) do
    # positions is a list of %{position: "PG", count: 1, ...}

    # We need to track which player IDs we've already assigned to avoid duplicates
    # if the data is messy, but strictly speaking we iterate through positions.

    # However, slots_map is %{"PG" => [id1], "C" => [id1, id2]}
    # We need to consume these IDs as we generate slots.

    {slots, _} =
      Enum.flat_map_reduce(positions, slots_map, fn position_def, current_slots_map ->
        # position_def.position is "PG"
        # position_def.count is 1 (or more)

        # Get the list of player IDs assigned to this position
        assigned_ids = Map.get(current_slots_map, position_def.position, [])

        # Take 'count' number of IDs (or nils if not enough)
        # We also need to remove them from the map for this position so we don't reuse them
        # (though typically we process each position type once)

        {ids_for_this_pos, remaining_ids} = Enum.split(assigned_ids, position_def.count)

        # If we have fewer IDs than count, pad with nils
        padded_ids =
          if length(ids_for_this_pos) < position_def.count do
            ids_for_this_pos ++ List.duplicate(nil, position_def.count - length(ids_for_this_pos))
          else
            ids_for_this_pos
          end

        # Create slots
        new_slots =
          Enum.map(padded_ids, fn scorer_id ->
            scorer = if scorer_id, do: Map.get(scorers_map, scorer_id), else: nil

            %{
              position: position_def.position,
              sub_positions: position_def.sub_positions,
              scorer: scorer,
              filled: !is_nil(scorer),
              roster_position: position_def
            }
          end)

        # Update map (though strictly we only visit each position key once usually)
        updated_map = Map.put(current_slots_map, position_def.position, remaining_ids)

        {new_slots, updated_map}
      end)

    slots
  end
end
