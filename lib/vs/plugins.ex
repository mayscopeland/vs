defmodule Vs.Plugins do
  @moduledoc """
  Plugin loader module for dynamically loading and executing plugin modules.
  """

  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.Scorer

  @doc """
  Loads initial player data from plugin JSON and inserts into the database.

  Returns {:ok, count} on success where count is the number of players loaded,
  or {:error, reason} on failure.

  ## Examples

      iex> load_initial_data("NBA", 2025, 1)
      {:ok, 450}

      iex> load_initial_data("NFL", 2024, 2)
      {:error, :plugin_not_found}
  """
  def load_initial_data(contest_type, season_year, universe_id) do
    alias Vs.Plugins.Registry

    with {:ok, players} <- Registry.get_plugin_players(contest_type, season_year),
         {:ok, count} <- insert_scorers(players, contest_type, universe_id) do
      {:ok, count}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Resolves a plugin module from a contest type string.

  ## Examples

      iex> resolve_plugin_module("NBA")
      {:ok, Vs.Plugins.NBA}

      iex> resolve_plugin_module("NFL")
      {:error, :plugin_not_found}
  """
  def resolve_plugin_module(contest_type) do
    module_name = "Elixir.Vs.Plugins.#{String.upcase(contest_type)}"

    try do
      module = String.to_existing_atom(module_name)

      # Verify the module implements the Plugin behaviour
      if function_exported?(module, :get_schedule, 1) do
        {:ok, module}
      else
        {:error, :plugin_not_found}
      end
    rescue
      ArgumentError -> {:error, :plugin_not_found}
    end
  end

  # Bulk inserts scorers into the database.
  # Uses insert_all for efficiency. Skips duplicates based on external_id and universe_id.
  defp insert_scorers(scorers, contest_type, universe_id) when is_list(scorers) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Add timestamps, contest_type, and universe_id to each scorer
    scorers_with_metadata =
      Enum.map(scorers, fn scorer ->
        scorer
        |> Map.put(:contest_type, contest_type)
        |> Map.put(:universe_id, universe_id)
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    # Check which scorers already exist in this universe
    external_ids = Enum.map(scorers, & &1.external_id) |> Enum.reject(&is_nil/1)

    existing_external_ids =
      from(s in Scorer,
        where: s.external_id in ^external_ids and s.universe_id == ^universe_id,
        select: s.external_id
      )
      |> Repo.all()
      |> MapSet.new()

    # Filter out existing scorers
    new_scorers =
      Enum.reject(scorers_with_metadata, fn scorer ->
        scorer.external_id && MapSet.member?(existing_external_ids, scorer.external_id)
      end)

    case new_scorers do
      [] ->
        {:ok, 0}

      scorers ->
        {count, _} = Repo.insert_all(Scorer, scorers)
        {:ok, count}
    end
  end

  defp insert_scorers(_, _, _), do: {:error, :invalid_scorers_data}
end
