defmodule Vs.Plugins do
  @moduledoc """
  Plugin loader module for dynamically loading and executing plugin modules.
  """

  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.Scorer

  @doc """
  Loads initial player data from a plugin and inserts into the database.

  Returns {:ok, count} on success where count is the number of players loaded,
  or {:error, reason} on failure.

  ## Examples

      iex> load_initial_data("NBA", 2024)
      {:ok, 450}

      iex> load_initial_data("NFL", 2024)
      {:error, :plugin_not_found}
  """
  def load_initial_data(contest_type, season_year) do
    with {:ok, plugin_module} <- resolve_plugin_module(contest_type),
         {:ok, data} <- plugin_module.get_initial_data(season_year),
         {:ok, count} <- insert_scorers(data.scorers) do
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
      if function_exported?(module, :get_initial_data, 1) do
        {:ok, module}
      else
        {:error, :plugin_not_found}
      end
    rescue
      ArgumentError -> {:error, :plugin_not_found}
    end
  end

  # Bulk inserts scorers into the database.
  # Uses insert_all for efficiency. Skips duplicates based on name and contest_type.
  defp insert_scorers(scorers) when is_list(scorers) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Add timestamps to each scorer
    scorers_with_timestamps =
      Enum.map(scorers, fn scorer ->
        scorer
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    # Check which scorers already exist
    names = Enum.map(scorers, & &1.name)

    existing_names =
      from(s in Scorer,
        where: s.name in ^names,
        select: s.name
      )
      |> Repo.all()
      |> MapSet.new()

    # Filter out existing scorers
    new_scorers =
      Enum.reject(scorers_with_timestamps, fn scorer ->
        MapSet.member?(existing_names, scorer.name)
      end)

    case new_scorers do
      [] ->
        {:ok, 0}

      scorers ->
        {count, _} = Repo.insert_all(Scorer, scorers)
        {:ok, count}
    end
  end

  defp insert_scorers(_), do: {:error, :invalid_scorers_data}
end
