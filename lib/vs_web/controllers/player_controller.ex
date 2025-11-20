defmodule VsWeb.PlayerController do
  use VsWeb, :controller

  import Ecto.Query
  alias Vs.{Leagues, Players, Repo}
  alias Vs.Stats.{Calculator, Formatter}

  def list(conn, %{"league_id" => league_id} = params) do
    league =
      league_id
      |> Leagues.get_league!()
      |> Repo.preload(scoring_categories: from(sc in Vs.ScoringCategory, order_by: sc.sequence))

    page = Map.get(params, "page", "1") |> String.to_integer()
    per_page = 50

    {players, total_count} = Players.list_available_players(league_id, page: page, per_page: per_page)
    total_pages = ceil(total_count / per_page)

    # Get aggregated stats for all players
    player_ids = Enum.map(players, & &1.id)
    player_stats = Players.get_player_stats(player_ids, league.season_year)

    # Calculate formula-based categories and format all values
    enhanced_stats =
      player_stats
      |> Enum.map(fn {scorer_id, stats} ->
        # Calculate formula-based categories
        calculated_stats =
          league.scoring_categories
          |> Enum.reduce(stats, fn category, acc ->
            if category.formula do
              # Calculate the formula value
              calculated_value = Calculator.calculate(category.formula, stats)
              Map.put(acc, category.name, calculated_value)
            else
              acc
            end
          end)

        # Format all values according to their format specification
        formatted_stats =
          league.scoring_categories
          |> Enum.map(fn category ->
            raw_value = Map.get(calculated_stats, category.name)
            formatted_value = Formatter.format(raw_value, category.format)
            {category.name, formatted_value}
          end)
          |> Map.new()

        {scorer_id, formatted_stats}
      end)
      |> Map.new()

    render(conn, :list,
      league: league,
      players: players,
      scoring_categories: league.scoring_categories,
      player_stats: enhanced_stats,
      page_title: "#{league.name} - Players",
      page: page,
      total_pages: total_pages
    )
  end
end
