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
  def load_initial_data(contest_type, season_year, league_id) do
    alias Vs.Plugins.Registry

    with {:ok, players} <- Registry.get_plugin_players(contest_type, season_year),
         {:ok, count} <- insert_scorers(players, contest_type, league_id) do
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

  @doc """
  Fetches observations for a specific date and stores them in the database.
  """
  def fetch_and_store_observations(contest_type, date, league_id) do
    with {:ok, module} <- resolve_plugin_module(contest_type),
         {:ok, %{player_stats: player_stats}} <- module.get_observations(date) do
      # Get all scorers for this league to map external_id -> id
      scorers_map =
        from(s in Scorer, where: s.league_id == ^league_id, select: {s.external_id, s.id})
        |> Repo.all()
        |> Map.new()

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      # Simplified season year logic
      season_year = date.year

      observations =
        player_stats
        |> Enum.map(fn stat ->
          external_id = Map.get(stat, "PLAYER_ID") |> to_string()
          scorer_id = Map.get(scorers_map, external_id)

          if scorer_id do
            %{
              contest_type: contest_type,
              season_year: season_year,
              game_date: date,
              scorer_id: scorer_id,
              # Store the entire stat map as JSON
              stats: stat,
              recorded_at: now,
              inserted_at: now,
              updated_at: now
            }
          else
            nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      # Upsert observations
      {_count, _} =
        Repo.insert_all(
          Vs.Observation,
          observations,
          on_conflict: {:replace, [:stats, :updated_at]},
          conflict_target: [:scorer_id, :game_date]
        )

      # Update Scorer stats with YTD totals
      update_scorer_ytd_stats(observations, season_year)

      {:ok, length(observations)}
    end
  end

  defp update_scorer_ytd_stats(observations, season_year) do
    scorer_ids = Enum.map(observations, & &1.scorer_id) |> Enum.uniq()

    # Fetch all observations for these scorers for the current season
    all_observations =
      from(o in Vs.Observation,
        where: o.scorer_id in ^scorer_ids and o.season_year == ^season_year,
        select: {o.scorer_id, o.stats}
      )
      |> Repo.all()

    # Group by scorer and aggregate
    aggregated_stats =
      all_observations
      |> Enum.group_by(fn {scorer_id, _stats} -> scorer_id end, fn {_scorer_id, stats} ->
        stats
      end)
      |> Enum.map(fn {scorer_id, stats_list} ->
        ytd_stats =
          Enum.reduce(stats_list, %{}, fn stats, acc ->
            Map.merge(acc, stats, fn _k, v1, v2 ->
              case {v1, v2} do
                {n1, n2} when is_number(n1) and is_number(n2) -> n1 + n2
                # Keep original value for non-numeric fields
                _ -> v1
              end
            end)
          end)

        {scorer_id, ytd_stats}
      end)

    # Update each scorer
    Enum.each(aggregated_stats, fn {scorer_id, ytd_stats} ->
      scorer = Repo.get(Scorer, scorer_id)

      # Merge new YTD stats into existing stats map under the season year key
      updated_stats = Map.put(scorer.stats, to_string(season_year), ytd_stats)

      scorer
      |> Scorer.changeset(%{stats: updated_stats})
      |> Repo.update!()
    end)
  end

  # Bulk inserts scorers into the database.
  # Uses insert_all for efficiency. Skips duplicates based on external_id and league_id.
  defp insert_scorers(scorers, contest_type, league_id) when is_list(scorers) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Add timestamps, contest_type, and league_id to each scorer
    scorers_with_metadata =
      Enum.map(scorers, fn scorer ->
        scorer
        |> Map.put(:contest_type, contest_type)
        |> Map.put(:league_id, league_id)
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    # Get existing scorers
    external_ids = Enum.map(scorers, & &1.external_id) |> Enum.reject(&is_nil/1)

    existing_scorers =
      from(s in Scorer,
        where: s.external_id in ^external_ids and s.league_id == ^league_id
      )
      |> Repo.all()
      |> Map.new(&{&1.external_id, &1})

    # Split into new and existing
    {new_scorers, updates} =
      Enum.split_with(scorers_with_metadata, fn s ->
        !Map.has_key?(existing_scorers, s.external_id)
      end)

    # Insert new scorers
    inserted_count =
      if new_scorers != [] do
        {count, _} = Repo.insert_all(Scorer, new_scorers)
        count
      else
        0
      end

    # Update existing scorers
    updated_count =
      Enum.reduce(updates, 0, fn new_data, acc ->
        existing = Map.get(existing_scorers, new_data.external_id)

        if existing.stats != new_data.stats do
          existing
          |> Scorer.changeset(%{stats: new_data.stats, updated_at: now})
          |> Repo.update!()

          acc + 1
        else
          acc
        end
      end)

    {:ok, inserted_count + updated_count}
  end

  defp insert_scorers(_, _, _), do: {:error, :invalid_scorers_data}
end
