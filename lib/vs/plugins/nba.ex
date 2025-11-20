defmodule Vs.Plugins.NBA do
  @behaviour Vs.Plugins.Plugin

  @base_url "https://stats.nba.com/stats"

  @headers [
    {"User-Agent",
     "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"},
    {"Accept", "*/*"},
    {"Accept-Language", "en-US,en;q=0.9"},
    {"Accept-Encoding", "gzip, deflate, br"},
    {"Referer", "https://www.nba.com/"},
    {"Origin", "https://www.nba.com"},
    {"Connection", "keep-alive"},
    {"DNT", "1"},
    {"Sec-Fetch-Dest", "empty"},
    {"Sec-Fetch-Mode", "cors"},
    {"Sec-Fetch-Site", "same-site"},
    {"sec-ch-ua", ~s("Google Chrome";v="141", "Not?A_Brand";v="8", "Chromium";v="141")},
    {"sec-ch-ua-mobile", "?0"},
    {"sec-ch-ua-platform", ~s("Windows")}
  ]

  @impl true
  def get_schedule(date) do
    date_struct = normalize_date(date)
    game_date = format_game_date(date_struct)

    url = "#{@base_url}/scoreboardv2"

    params = [
      GameDate: game_date,
      LeagueID: "00",
      DayOffset: "0"
    ]

    case HTTPoison.get(url, @headers, params: params, timeout: 20_000, recv_timeout: 20_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        decompressed_body = decompress_if_needed(body)

        case Jason.decode(decompressed_body) do
          {:ok, data} ->
            games = parse_schedule(data)
            {:ok, %{games: games, raw: Map.get(data, "resultSets", [])}}

          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:http_request_failed, reason}}
    end
  end

  @impl true
  def get_observations(date) do
    date_struct = normalize_date(date)
    date_string = Date.to_iso8601(date_struct)
    season_string = calculate_season_string(date_struct)

    url = "#{@base_url}/leaguedashplayerstats"

    params = [
      DateFrom: date_string,
      DateTo: date_string,
      Season: season_string,
      SeasonType: "Regular Season",
      MeasureType: "Base",
      LastNGames: "0",
      Month: "0",
      OpponentTeamID: "0",
      PaceAdjust: "N",
      PerMode: "Totals",
      Period: "0",
      PlusMinus: "N",
      Rank: "N",
      GameScope: "",
      GameSegment: "",
      Location: "",
      Outcome: "",
      PlayerExperience: "",
      PlayerPosition: "",
      SeasonSegment: "",
      StarterBench: "",
      VsConference: "",
      VsDivision: ""
    ]

    case HTTPoison.get(url, @headers, params: params, timeout: 20_000, recv_timeout: 20_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        decompressed_body = decompress_if_needed(body)

        case Jason.decode(decompressed_body) do
          {:ok, data} ->
            player_stats = parse_observations(data)
            {:ok, %{player_stats: player_stats}}

          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:http_request_failed, reason}}
    end
  end

  defp format_season(year) do
    next_year = rem(year + 1, 100)
    next_year_str = String.pad_leading(to_string(next_year), 2, "0")
    "#{year}-#{next_year_str}"
  end

  defp format_game_date(%Date{month: month, day: day, year: year}) do
    "#{String.pad_leading(to_string(month), 2, "0")}/#{String.pad_leading(to_string(day), 2, "0")}/#{year}"
  end

  defp calculate_season_string(%Date{year: year, month: month}) do
    season_start_year =
      if month <= 4 do
        year - 1
      else
        year
      end

    format_season(season_start_year)
  end

  defp normalize_date(%Date{} = date), do: date

  defp normalize_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> raise "Invalid date string: #{date_string}"
    end
  end

  defp parse_schedule(data) do
    result_sets = Map.get(data, "resultSets", [])

    sets_map =
      Enum.reduce(result_sets, %{}, fn rs, acc ->
        name = Map.get(rs, "name")
        if name, do: Map.put(acc, name, rs), else: acc
      end)

    game_header_set = Map.get(sets_map, "GameHeader", %{})
    headers = Map.get(game_header_set, "headers", [])
    rows = Map.get(game_header_set, "rowSet", [])

    game_header =
      Enum.map(rows, fn row ->
        headers
        |> Enum.zip(row)
        |> Map.new()
      end)

    keep_keys =
      MapSet.new([
        "GAME_ID",
        "GAME_DATE_EST",
        "GAME_STATUS_TEXT",
        "HOME_TEAM_ID",
        "VISITOR_TEAM_ID",
        "GAMECODE",
        "ARENA_NAME",
        "HOME_TEAM_ABBREVIATION",
        "VISITOR_TEAM_ABBREVIATION",
        "HOME_TEAM_CITY",
        "VISITOR_TEAM_CITY"
      ])

    Enum.map(game_header, fn game ->
      game
      |> Enum.filter(fn {key, _value} -> MapSet.member?(keep_keys, key) end)
      |> Map.new()
    end)
  end

  defp parse_observations(data) do
    result_sets = Map.get(data, "resultSets", [])

    if result_sets == [] do
      []
    else
      result_set = List.first(result_sets)
      headers = Map.get(result_set, "headers", [])
      rows = Map.get(result_set, "rowSet", [])

      rows_as_maps =
        Enum.map(rows, fn row ->
          headers
          |> Enum.zip(row)
          |> Map.new()
        end)

      # Keep only counting stats (exclude rates/percentages)
      allow_keys =
        MapSet.new([
          "PLAYER_ID",
          "PLAYER_NAME",
          "TEAM_ID",
          "TEAM_ABBREVIATION",
          "GP",
          "MIN",
          "FGM",
          "FGA",
          "FG3M",
          "FG3A",
          "FTM",
          "FTA",
          "OREB",
          "DREB",
          "REB",
          "AST",
          "STL",
          "BLK",
          "TOV",
          "PF",
          "PTS"
        ])

      Enum.map(rows_as_maps, fn row ->
        row
        |> Enum.filter(fn {key, _value} ->
          MapSet.member?(allow_keys, key) and not String.ends_with?(key, "_PCT")
        end)
        |> Map.new()
      end)
    end
  end

  defp decompress_if_needed(body) do
    case body do
      <<31, 139, 8, _rest::binary>> ->
        :zlib.gunzip(body)

      _ ->
        body
    end
  end
end
