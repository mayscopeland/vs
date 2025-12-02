defmodule VsWeb.PlayerController do
  use VsWeb, :controller

  alias Vs.{Seasons, Players}
  alias Vs.Stats.Formatter

  def list(conn, %{"season_id" => season_id} = params) do
    season =
      season_id
      |> Seasons.get_season!()

    scoring_categories = Seasons.get_active_scoring_categories(season)

    page = Map.get(params, "page", "1") |> String.to_integer()
    per_page = 50
    stat_source = Map.get(params, "stat_source", to_string(season.season_year))
    sort_by = Map.get(params, "sort_by", "rank")
    sort_dir = Map.get(params, "sort_dir", "asc")

    {players, total_count} =
      Players.list_available_players(season_id,
        page: page,
        per_page: per_page,
        sort_by: sort_by,
        sort_dir: sort_dir,
        stat_source: stat_source
      )

    total_pages = ceil(total_count / per_page)

    # Players now come with stats pre-calculated and populated in the struct
    # We just need to format them for display if needed, but the view expects raw values or formatted?
    # The view calls Formatter.format inside the loop? No, the controller did it.
    # Let's check the view again.
    # The view does: <%= get_in(@player_stats, [player.id, category.name]) || "-" %>
    # But wait, the controller was creating a map of {scorer_id => formatted_stats}.
    # Now `players` is a list of structs where `player.stats` is the map of calculated values.
    # So we need to adapt the view or the controller to match.
    # It's cleaner to format here and pass a map like before to minimize view changes,
    # OR update the view to use `player.stats`.
    # Let's update the controller to produce the expected `@player_stats` map for compatibility.

    enhanced_stats =
      players
      |> Enum.map(fn player ->
        formatted_stats =
          scoring_categories
          |> Enum.map(fn category ->
            raw_value = Map.get(player.stats, category.name)
            formatted_value = Formatter.format(raw_value, category.format)
            {category.name, formatted_value}
          end)
          |> Map.new()

        {player.id, formatted_stats}
      end)
      |> Map.new()

    # Generate options for the dropdown
    current_year = season.season_year

    stat_source_options = [
      {"#{current_year} Stats", to_string(current_year)},
      {"#{current_year} Preseason Projections", "projection"},
      {"#{current_year - 1} Stats", to_string(current_year - 1)},
      {"#{current_year - 2} Stats", to_string(current_year - 2)},
      {"#{current_year - 3} Stats", to_string(current_year - 3)}
    ]

    # Get position colors from season roster settings
    position_colors =
      (season.roster_settings || [])
      |> Enum.map(fn setting ->
        # Handle string keys from JSON
        position = Map.get(setting, "position") || Map.get(setting, :position)
        color = Map.get(setting, "color") || Map.get(setting, :color)
        {position, color}
      end)
      |> Map.new()

    render(conn, :list,
      season: season,
      players: players,
      scoring_categories: scoring_categories,
      player_stats: enhanced_stats,
      page_title: "#{season.name} - Players",
      page: page,
      total_pages: total_pages,
      stat_source: stat_source,
      stat_source_options: stat_source_options,
      sort_by: sort_by,
      sort_dir: sort_dir,
      position_colors: position_colors
    )
  end

  def show(conn, %{"season_id" => season_id, "id" => player_id} = _params) do
    season = Seasons.get_season!(season_id)
    player = Players.get_scorer!(player_id)
    scoring_categories = Seasons.get_active_scoring_categories(season)

    # Generate stat source options (same labels as player list dropdown)
    current_year = season.season_year

    stat_source_options = [
      {"#{current_year} Stats", to_string(current_year)},
      {"#{current_year} Preseason Projections", "projection"},
      {"#{current_year - 1} Stats", to_string(current_year - 1)},
      {"#{current_year - 2} Stats", to_string(current_year - 2)},
      {"#{current_year - 3} Stats", to_string(current_year - 3)}
    ]

    # Build stats for each year/source
    stats_by_year =
      stat_source_options
      |> Enum.map(fn {label, source_key} ->
        raw_stats = Map.get(player.stats, source_key, %{})

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

        # Format stats for display
        formatted_stats =
          scoring_categories
          |> Enum.map(fn category ->
            raw_value = Map.get(calculated_stats, category.name)
            formatted_value = Formatter.format(raw_value, category.format)
            {category.name, formatted_value}
          end)
          |> Map.new()

        {label, source_key, formatted_stats}
      end)

    render(conn, :show,
      season: season,
      player: player,
      scoring_categories: scoring_categories,
      stats_by_year: stats_by_year,
      layout: false
    )
  end
end
