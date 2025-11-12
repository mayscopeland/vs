defmodule Vs.Leagues do
  @moduledoc """
  The Leagues context - handles league and universe management.
  """

  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.{League, Universe, Period, RosterPosition, ScoringCategory}

  @doc """
  Returns the list of all leagues ordered by season year (desc) and name.
  """
  def list_leagues do
    League
    |> order_by([l], desc: l.season_year, asc: l.name)
    |> Repo.all()
    |> Repo.preload(:universe)
  end

  @doc """
  Gets a single league by ID with universe preloaded.

  Raises `Ecto.NoResultsError` if the League does not exist.
  """
  def get_league!(id) do
    League
    |> Repo.get!(id)
    |> Repo.preload(:universe)
  end

  @doc """
  Creates a universe.

  ## Examples

      iex> create_universe(%{contest_type: "NBA"})
      {:ok, %Universe{}}

      iex> create_universe(%{contest_type: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_universe(attrs \\ %{}) do
    %Universe{}
    |> Universe.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a league.

  ## Examples

      iex> create_league(%{name: "My League", season_year: 2024, universe_id: 1})
      {:ok, %League{}}

      iex> create_league(%{name: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_league(attrs \\ %{}) do
    %League{}
    |> League.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sets up league defaults from plugin configuration.

  Creates periods, roster positions, and scoring categories based on the plugin config.
  """
  def setup_league_defaults(league, plugin_config) do
    Repo.transaction(fn ->
      # Create periods
      plugin_config.periods
      |> Enum.each(fn period_data ->
        %Period{}
        |> Period.changeset(Map.put(period_data, :league_id, league.id))
        |> Repo.insert!()
      end)

      # Create roster positions
      plugin_config.roster_positions
      |> Enum.each(fn position_data ->
        %RosterPosition{}
        |> RosterPosition.changeset(Map.put(position_data, :league_id, league.id))
        |> Repo.insert!()
      end)

      # Create scoring categories
      plugin_config.scoring_categories
      |> Enum.each(fn category_data ->
        %ScoringCategory{}
        |> ScoringCategory.changeset(Map.put(category_data, :league_id, league.id))
        |> Repo.insert!()
      end)

      league
    end)
  end
end
