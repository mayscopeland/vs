defmodule Vs.Leagues do


  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{League, Universe, Period, RosterPosition, ScoringCategory}

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

      # Create roster positions from first position preset
      first_position_preset = List.first(plugin_config.position_presets)

      if first_position_preset do
        first_position_preset.positions
        |> Enum.with_index(1)
        |> Enum.each(fn {{position, count}, sequence} ->
          %RosterPosition{}
          |> RosterPosition.changeset(%{
            league_id: league.id,
            position: position,
            count: count,
            sequence: sequence
          })
          |> Repo.insert!()
        end)
      end

      # Create scoring categories from first category preset
      first_category_preset = List.first(plugin_config.category_presets)

      if first_category_preset do
        # Build a map of category name -> available category info for lookup
        available_categories_map =
          plugin_config.available_categories
          |> Enum.map(fn cat -> {cat.name, cat} end)
          |> Map.new()

        first_category_preset.categories
        |> Enum.with_index(1)
        |> Enum.each(fn {{name, multiplier}, sequence} ->
          # Look up formula and format from available_categories
          available_cat = Map.get(available_categories_map, name)
          formula = if available_cat, do: available_cat.formula, else: nil
          format = if available_cat, do: available_cat.format, else: "integer"

          %ScoringCategory{}
          |> ScoringCategory.changeset(%{
            league_id: league.id,
            name: name,
            multiplier: multiplier,
            formula: formula,
            format: format,
            sequence: sequence
          })
          |> Repo.insert!()
        end)
      end

      league
    end)
  end
end
