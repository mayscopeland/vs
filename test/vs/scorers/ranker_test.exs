defmodule Vs.Scorers.RankerTest do
  use Vs.DataCase

  alias Vs.Scorers.Ranker
  alias Vs.{Leagues, Scorer}

  describe "calculate_ranks/1" do
    setup do
      universe = insert_universe(%{contest_type: "NBA"})
      league = insert_league(%{universe_id: universe.id, season_year: 2025})

      # Create scorers with stats
      scorer1 =
        insert_scorer(%{
          universe_id: universe.id,
          name: "Player A",
          stats: %{
            # 50% FG
            "2025" => %{"PTS" => 20, "REB" => 10, "AST" => 5, "TOV" => 2, "FGM" => 8, "FGA" => 16},
            "2024" => %{"PTS" => 10}
          }
        })

      scorer2 =
        insert_scorer(%{
          universe_id: universe.id,
          name: "Player B",
          stats: %{
            # 40% FG
            "2025" => %{"PTS" => 30, "REB" => 5, "AST" => 2, "TOV" => 5, "FGM" => 12, "FGA" => 30},
            "2024" => %{"PTS" => 20}
          }
        })

      %{league: league, scorers: [scorer1, scorer2]}
    end

    test "calculates ranks for points league", %{league: league} do
      # Setup points settings: PTS=1, REB=1, AST=1, TOV=-1
      settings = %{
        "PTS" => 1,
        "REB" => 1,
        "AST" => 1,
        "TOV" => -1
      }

      {:ok, league} =
        Leagues.update_league(league, %{scoring_settings: settings, scoring_type: "points"})

      # Run ranker
      Ranker.calculate_ranks(league)

      # Check ranks
      # Player A: 20 + 10 + 5 - 2 = 33
      # Player B: 30 + 5 + 2 - 5 = 32
      # Player A should be rank 1, Player B rank 2

      s1 = Repo.get_by(Scorer, name: "Player A")
      s2 = Repo.get_by(Scorer, name: "Player B")

      assert s1.rank["2025"] == 1
      assert s2.rank["2025"] == 2

      # 2024: A=10, B=20 -> B=1, A=2
      assert s1.rank["2024"] == 2
      assert s2.rank["2024"] == 1
    end

    test "calculates ranks for roto league with rate stats", %{league: league} do
      # Setup roto settings: PTS, FG%
      # FG% formula is FGM / FGA
      settings = %{
        "PTS" => 1,
        "FG%" => 1
      }

      {:ok, league} =
        Leagues.update_league(league, %{scoring_settings: settings, scoring_type: "roto"})

      Ranker.calculate_ranks(league)

      s1 = Repo.get_by(Scorer, name: "Player A")
      s2 = Repo.get_by(Scorer, name: "Player B")

      assert s1.rank["2025"]
      assert s2.rank["2025"]
    end
  end

  defp get_scorers do
    Repo.all(Scorer)
  end

  # Helpers for inserting data if not available in DataCase
  defp insert_universe(attrs) do
    %Vs.Universe{}
    |> Vs.Universe.changeset(attrs)
    |> Repo.insert!()
  end

  defp insert_league(attrs) do
    defaults = %{name: "Test League"}
    attrs = Map.merge(defaults, attrs)

    %Vs.League{}
    |> Vs.League.changeset(attrs)
    |> Repo.insert!()
  end

  defp insert_scorer(attrs) do
    defaults = %{contest_type: "NBA"}
    attrs = Map.merge(defaults, attrs)

    %Vs.Scorer{}
    |> Vs.Scorer.changeset(attrs)
    |> Repo.insert!()
  end
end
