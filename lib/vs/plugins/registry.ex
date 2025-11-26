defmodule Vs.Plugins.Registry do
  @plugins_dir "priv/plugins"

  def get_plugin_config(contest_type, year) do
    file_path = plugin_file_path(contest_type, year)

    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, raw_config} ->
              {:ok, parse_config(raw_config)}

            {:error, reason} ->
              {:error, {:parse_error, reason}}
          end

        {:error, reason} ->
          {:error, {:parse_error, reason}}
      end
    else
      {:error, :not_found}
    end
  end

  def get_plugin_config!(contest_type, year) do
    case get_plugin_config(contest_type, year) do
      {:ok, config} ->
        config

      {:error, :not_found} ->
        raise "Plugin configuration not found for contest type: #{contest_type} and year: #{year}"

      {:error, {:parse_error, reason}} ->
        raise "Failed to parse plugin configuration for #{contest_type}: #{inspect(reason)}"
    end
  end

  def get_plugin_players(contest_type, year) do
    file_path = plugin_players_file_path(contest_type, year)

    if File.exists?(file_path) do
      case File.read(file_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, %{"players" => players}} ->
              {:ok, parse_players(players)}

            {:error, reason} ->
              {:error, {:parse_error, reason}}
          end

        {:error, reason} ->
          {:error, {:parse_error, reason}}
      end
    else
      {:error, :not_found}
    end
  end

  def get_plugin_players!(contest_type, year) do
    case get_plugin_players(contest_type, year) do
      {:ok, players} ->
        players

      {:error, :not_found} ->
        raise "Player data not found for contest type: #{contest_type} and year: #{year}"

      {:error, {:parse_error, reason}} ->
        raise "Failed to parse player data for #{contest_type}: #{inspect(reason)}"
    end
  end

  def list_available_contest_types do
    plugins_dir = plugins_directory()

    if File.exists?(plugins_dir) do
      plugins_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".json"))
      |> Enum.reject(&String.ends_with?(&1, "_players.json"))
      |> Enum.map(&parse_plugin_filename/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn {_type, year} -> -year end)
    else
      []
    end
  end

  def plugin_exists?(contest_type, year) do
    contest_type
    |> plugin_file_path(year)
    |> File.exists?()
  end

  defp plugins_directory do
    Application.app_dir(:vs, @plugins_dir)
  end

  defp plugin_file_path(contest_type, year) do
    filename = "#{String.downcase(contest_type)}_#{year}.json"
    Path.join(plugins_directory(), filename)
  end

  defp plugin_players_file_path(contest_type, year) do
    filename = "#{String.downcase(contest_type)}_#{year}_players.json"
    Path.join(plugins_directory(), filename)
  end

  defp parse_plugin_filename(filename) do
    # Parse filenames like "nba_2025.json" -> {"NBA", 2025}
    case Regex.run(~r/^([a-z]+)_(\d{4})\.json$/, filename) do
      [_, contest_type, year_str] ->
        {String.upcase(contest_type), String.to_integer(year_str)}

      _ ->
        nil
    end
  end

  defp parse_config(raw_config) do
    %{
      contest_type: raw_config["contest_type"],
      season: parse_season(raw_config["season"]),
      periods: parse_periods(raw_config["periods"]),
      available_categories: parse_available_categories(raw_config["available_categories"]),
      category_presets: parse_category_presets(raw_config["category_presets"]),
      available_positions: parse_available_positions(raw_config["available_positions"]),
      position_presets: parse_position_presets(raw_config["position_presets"])
    }
  end

  defp parse_season(nil), do: nil

  defp parse_season(season_data) do
    %{
      year: season_data["year"],
      start_date: parse_date(season_data["start_date"]),
      end_date: parse_date(season_data["end_date"])
    }
  end

  defp parse_periods(nil), do: []

  defp parse_periods(periods_list) do
    Enum.map(periods_list, fn period ->
      %{
        sequence: period["sequence"],
        start_date: parse_date(period["start_date"]),
        end_date: parse_date(period["end_date"]),
        is_playoff: period["is_playoff"] || false
      }
    end)
  end

  defp parse_available_categories(nil), do: []

  defp parse_available_categories(categories_list) do
    Enum.map(categories_list, fn category ->
      %{
        name: category["name"],
        description: category["description"],
        formula: category["formula"],
        format: category["format"] || "integer"
      }
    end)
  end

  defp parse_category_presets(nil), do: []

  defp parse_category_presets(presets_list) do
    Enum.map(presets_list, fn preset ->
      %{
        name: preset["name"],
        type: preset["type"],
        description: preset["description"],
        categories: preset["categories"] || %{}
      }
    end)
  end

  defp parse_available_positions(nil), do: []

  defp parse_available_positions(positions_list) do
    Enum.map(positions_list, fn position ->
      %{
        name: position["name"],
        display_name: position["display_name"],
        # Default to "Roster" if not specified
        group: position["group"] || "Roster"
      }
    end)
  end

  defp parse_position_presets(nil), do: []

  defp parse_position_presets(presets_list) do
    Enum.map(presets_list, fn preset ->
      %{
        name: preset["name"],
        positions: preset["positions"] || %{}
      }
    end)
  end

  defp parse_date(nil), do: nil

  defp parse_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  defp parse_players(players_list) when is_list(players_list) do
    Enum.map(players_list, fn player ->
      %{
        name: player["name"],
        team: player["team"],
        position: player["position"],
        external_id: player["external_id"],
        stats: player["stats"] || %{}
      }
    end)
  end

  defp parse_players(_), do: []
end
