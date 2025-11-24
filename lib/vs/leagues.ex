defmodule Vs.Leagues do
  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{League, Universe, Period}

  def list_leagues do
    League
    |> order_by([l], desc: l.season_year, asc: l.name)
    |> Repo.all()
    |> Repo.preload(:universe)
  end

  def get_league!(id) do
    League
    |> Repo.get!(id)
    |> Repo.preload(:universe)
  end

  def create_universe(attrs \\ %{}) do
    %Universe{}
    |> Universe.changeset(attrs)
    |> Repo.insert()
  end

  def create_league(attrs \\ %{}) do
    %League{}
    |> League.changeset(attrs)
    |> Repo.insert()
  end

  def setup_league_defaults(league, plugin_config) do
    Repo.transaction(fn ->
      # Create periods
      plugin_config.periods
      |> Enum.each(fn period_data ->
        %Period{}
        |> Period.changeset(Map.put(period_data, :league_id, league.id))
        |> Repo.insert!()
      end)

      # Get defaults from presets
      roster_settings =
        case List.first(plugin_config.position_presets) do
          nil -> %{}
          preset -> preset.positions
        end

      scoring_settings =
        case List.first(plugin_config.category_presets) do
          nil -> %{}
          preset -> preset.categories
        end

      # Update league with defaults
      league
      |> League.changeset(%{
        roster_settings: roster_settings,
        scoring_settings: scoring_settings
      })
      |> Repo.update!()
    end)
  end

  def get_active_scoring_categories(league) do
    # Ensure universe is loaded
    league = Repo.preload(league, :universe)

    config =
      Vs.Plugins.Registry.get_plugin_config!(league.universe.contest_type, league.season_year)

    settings = league.scoring_settings || %{}

    config.available_categories
    |> Enum.filter(fn cat -> Map.has_key?(settings, cat.name) end)
    |> Enum.map(fn cat ->
      Map.put(cat, :multiplier, Map.get(settings, cat.name))
    end)
  end

  def get_active_roster_positions(league) do
    # Ensure universe is loaded
    league = Repo.preload(league, :universe)

    config =
      Vs.Plugins.Registry.get_plugin_config!(league.universe.contest_type, league.season_year)

    settings = league.roster_settings || %{}

    # Create a map of available positions for ordering and metadata
    available_positions = config.available_positions

    # We want to return a list of %{position: "PG", count: 1, group: <from config>, ...}
    # We iterate through available_positions to maintain order
    available_positions
    |> Enum.filter(fn pos -> Map.has_key?(settings, pos.name) end)
    |> Enum.map(fn pos ->
      count = Map.get(settings, pos.name)

      %{
        position: pos.name,
        display_name: pos.display_name,
        count: count,
        # Use group from position config
        group: pos.group,
        # We can add logic for sub-positions later if needed
        sub_positions: nil
      }
    end)
  end
end
