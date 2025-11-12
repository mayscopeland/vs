defmodule Vs.Plugins.Registry do
  @plugins_dir "priv/plugins"

  def get_plugin_config(contest_type) do
    file_path = plugin_file_path(contest_type)

    if File.exists?(file_path) do
      case Toml.decode_file(file_path) do
        {:ok, raw_config} ->
          {:ok, parse_config(raw_config)}

        {:error, reason} ->
          {:error, {:parse_error, reason}}
      end
    else
      {:error, :not_found}
    end
  end

  def get_plugin_config!(contest_type) do
    case get_plugin_config(contest_type) do
      {:ok, config} ->
        config

      {:error, :not_found} ->
        raise "Plugin configuration not found for contest type: #{contest_type}"

      {:error, {:parse_error, reason}} ->
        raise "Failed to parse plugin configuration for #{contest_type}: #{inspect(reason)}"
    end
  end

  def list_available_contest_types do
    plugins_dir = plugins_directory()

    if File.exists?(plugins_dir) do
      plugins_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".toml"))
      |> Enum.map(&String.replace_suffix(&1, ".toml", ""))
      |> Enum.map(&String.upcase/1)
      |> Enum.sort()
    else
      []
    end
  end

  def plugin_exists?(contest_type) do
    contest_type
    |> plugin_file_path()
    |> File.exists?()
  end

  defp plugins_directory do
    Application.app_dir(:vs, @plugins_dir)
  end

  defp plugin_file_path(contest_type) do
    filename = "#{String.downcase(contest_type)}.toml"
    Path.join(plugins_directory(), filename)
  end

  defp parse_config(raw_config) do
    %{
      contest_type: raw_config["contest_type"],
      season: parse_season(raw_config["season"]),
      periods: parse_periods(raw_config["periods"]),
      roster_positions: parse_roster_positions(raw_config["roster_positions"]),
      scoring_categories: parse_scoring_categories(raw_config["scoring_categories"])
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
        name: period["name"],
        sequence: period["sequence"],
        start_date: parse_date(period["start_date"]),
        end_date: parse_date(period["end_date"]),
        is_playoff: period["is_playoff"] || false
      }
    end)
  end

  defp parse_roster_positions(nil), do: []

  defp parse_roster_positions(positions_list) do
    Enum.map(positions_list, fn position ->
      %{
        position: position["position"],
        count: position["count"],
        sequence: position["sequence"]
      }
    end)
  end

  defp parse_scoring_categories(nil), do: []

  defp parse_scoring_categories(categories_list) do
    Enum.map(categories_list, fn category ->
      %{
        name: category["name"],
        multiplier: category["multiplier"] || 1.0,
        sequence: category["sequence"]
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
end
