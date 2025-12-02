defmodule Vs.Seasons do
  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{Season, Period}

  def list_seasons do
    Season
    |> order_by([s], desc: s.season_year, asc: s.name)
    |> Repo.all()
    |> Repo.preload(:league)
  end

  def get_season!(id) do
    Season
    |> Repo.get!(id)
    |> Repo.preload(:league)
  end

  def create_season(attrs \\ %{}) do
    %Season{}
    |> Season.changeset(attrs)
    |> Repo.insert()
  end

  def update_season(%Season{} = season, attrs) do
    result =
      season
      |> Season.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_season} ->
        # Recalculate ranks if scoring settings changed
        # For simplicity, we just always recalculate if update succeeds
        Vs.Scorers.Ranker.calculate_ranks(updated_season)
        {:ok, updated_season}

      error ->
        error
    end
  end

  def setup_season_defaults(season, plugin_config) do
    Repo.transaction(fn ->
      # Create periods
      plugin_config.periods
      |> Enum.each(fn period_data ->
        %Period{}
        |> Period.changeset(Map.put(period_data, :season_id, season.id))
        |> Repo.insert!()
      end)

      # Get defaults from presets
      roster_settings =
        case List.first(plugin_config.position_presets) do
          nil -> []
          preset -> preset.positions
        end

      {scoring_settings, scoring_type} =
        case List.first(plugin_config.category_presets) do
          nil -> {%{}, "points"}
          preset -> {preset.categories, Map.get(preset, "type", "points")}
        end

      # Update season with defaults
      season =
        season
        |> Season.changeset(%{
          roster_settings: roster_settings,
          scoring_settings: scoring_settings,
          scoring_type: scoring_type
        })
        |> Repo.update!()

      # Calculate initial ranks
      Vs.Scorers.Ranker.calculate_ranks(season)

      season
    end)
  end

  def get_active_scoring_categories(season) do
    # Ensure league is loaded
    season = Repo.preload(season, :league)

    config =
      Vs.Plugins.Registry.get_plugin_config!(season.league.contest_type, season.season_year)

    settings = season.scoring_settings || %{}

    config.available_categories
    |> Enum.filter(fn cat -> Map.has_key?(settings, cat.name) end)
    |> Enum.map(fn cat ->
      Map.put(cat, :multiplier, Map.get(settings, cat.name))
    end)
  end

  def get_active_roster_positions(season) do
    # Ensure league is loaded
    season = Repo.preload(season, :league)

    config =
      Vs.Plugins.Registry.get_plugin_config!(season.league.contest_type, season.season_year)

    settings = season.roster_settings || []

    # We want to return a list of %{position: "PG", count: 1, group: <from config>, color: <from settings>}
    # We iterate through `settings` (the list) to maintain the user-defined order.

    # Create a lookup for available positions metadata (display_name, group)
    available_positions_map =
      config.available_positions
      |> Map.new(fn p -> {p.name, p} end)

    settings
    |> Enum.map(fn pos_setting ->
      # Handle potential string/atom keys from JSON/Ecto
      position_name = Map.get(pos_setting, "position") || Map.get(pos_setting, :position)
      count = Map.get(pos_setting, "count") || Map.get(pos_setting, :count)
      color = Map.get(pos_setting, "color") || Map.get(pos_setting, :color)

      position_meta =
        Map.get(available_positions_map, position_name, %{
          display_name: position_name,
          group: "Roster"
        })

      %{
        position: position_name,
        display_name: position_meta.display_name,
        count: count,
        group: position_meta.group,
        color: color,
        sub_positions: nil
      }
    end)
  end
end
