defmodule Vs.PlayersTest do
  use Vs.DataCase

  alias Vs.Players
  alias Vs.Repo
  alias Vs.Universe
  alias Vs.League
  alias Vs.Team
  alias Vs.Scorer
  alias Vs.Roster
  alias Vs.Period

  describe "list_available_players/2" do
    setup do
      # Create universe
      universe = Repo.insert!(%Universe{contest_type: "NBA"})

      # Create league
      league =
        Repo.insert!(%League{
          name: "Test League",
          universe_id: universe.id,
          season_year: 2025,
          scoring_settings: %{},
          roster_settings: %{}
        })

      # Create period
      period =
        Repo.insert!(%Period{
          name: "Week 1",
          sequence: 1,
          start_date: ~D[2025-01-01],
          end_date: ~D[2025-01-07],
          league_id: league.id
        })

      # Create team
      team =
        Repo.insert!(%Team{
          name: "Test Team",
          league_id: league.id
        })

      # Create scorers
      scorer1 =
        Repo.insert!(%Scorer{
          name: "Player A",
          universe_id: universe.id,
          contest_type: "NBA",
          stats: %{"2025" => %{"PTS" => 20.0, "AST" => 5.0}}
        })

      scorer2 =
        Repo.insert!(%Scorer{
          name: "Player B",
          universe_id: universe.id,
          contest_type: "NBA",
          stats: %{"2025" => %{"PTS" => 15.0, "AST" => 10.0}}
        })

      scorer3 =
        Repo.insert!(%Scorer{
          name: "Player C",
          universe_id: universe.id,
          contest_type: "NBA",
          stats: %{"2025" => %{"PTS" => 25.0, "AST" => 2.0}}
        })

      %{league: league, team: team, period: period, scorers: [scorer1, scorer2, scorer3]}
    end

    test "returns all available players", %{league: league} do
      {players, count} = Players.list_available_players(league.id, stat_source: "2025")
      assert count == 3
      assert length(players) == 3
    end

    test "excludes rostered players", %{
      league: league,
      team: team,
      period: period,
      scorers: [s1, _s2, _s3]
    } do
      # Roster player 1
      Repo.insert!(%Roster{
        team_id: team.id,
        period_id: period.id,
        slots: %{"PG" => s1.id}
      })

      {players, count} = Players.list_available_players(league.id, stat_source: "2025")
      assert count == 2
      assert length(players) == 2
      refute Enum.any?(players, fn p -> p.id == s1.id end)
    end

    test "sorts by name ascending", %{league: league} do
      {players, _count} =
        Players.list_available_players(league.id,
          sort_by: "name",
          sort_dir: "asc",
          stat_source: "2025"
        )

      assert Enum.map(players, & &1.name) == ["Player A", "Player B", "Player C"]
    end

    test "sorts by name descending", %{league: league} do
      {players, _count} =
        Players.list_available_players(league.id,
          sort_by: "name",
          sort_dir: "desc",
          stat_source: "2025"
        )

      assert Enum.map(players, & &1.name) == ["Player C", "Player B", "Player A"]
    end

    test "sorts by stat category ascending", %{league: league} do
      {players, _count} =
        Players.list_available_players(league.id,
          sort_by: "PTS",
          sort_dir: "asc",
          stat_source: "2025"
        )

      assert Enum.map(players, & &1.name) == ["Player B", "Player A", "Player C"]
    end

    test "sorts by stat category descending", %{league: league} do
      {players, _count} =
        Players.list_available_players(league.id,
          sort_by: "PTS",
          sort_dir: "desc",
          stat_source: "2025"
        )

      assert Enum.map(players, & &1.name) == ["Player C", "Player A", "Player B"]
    end

    test "paginates results", %{league: league} do
      {players, count} =
        Players.list_available_players(league.id,
          page: 1,
          per_page: 2,
          sort_by: "name",
          sort_dir: "asc",
          stat_source: "2025"
        )

      assert count == 3
      assert length(players) == 2
      assert Enum.map(players, & &1.name) == ["Player A", "Player B"]

      {players, count} =
        Players.list_available_players(league.id,
          page: 2,
          per_page: 2,
          sort_by: "name",
          sort_dir: "asc",
          stat_source: "2025"
        )

      assert count == 3
      assert length(players) == 1
      assert Enum.map(players, & &1.name) == ["Player C"]
    end
  end
end
