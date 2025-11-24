
import json
import gzip
import requests
import time
from pathlib import Path

BASE_URL = "https://stats.nba.com/stats"
SEASON = "2025-26"

HEADERS = {
    "Host": "stats.nba.com",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    "Connection": "keep-alive",
    "Referer": "https://stats.nba.com/",
    "Pragma": "no-cache",
    "Cache-Control": "no-cache",
    "Sec-Ch-Ua": '"Chromium";v="140", "Google Chrome";v="140", "Not;A=Brand";v="24"',
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Fetch-Dest": "empty",
}



def fetch_season_stats(season, session):
    url = f"{BASE_URL}/leaguedashplayerstats"

    # Match nba_api parameters exactly with all defaults
    params = {
        "LastNGames": "0",
        "MeasureType": "Base",
        "Month": "0",
        "OpponentTeamID": "0",
        "PaceAdjust": "N",
        "PerMode": "Totals",
        "Period": "0",
        "PlusMinus": "N",
        "Rank": "N",
        "Season": season,
        "SeasonType": "Regular Season",
        "College": "",
        "Conference": "",
        "Country": "",
        "DateFrom": "",
        "DateTo": "",
        "Division": "",
        "DraftPick": "",
        "DraftYear": "",
        "GameScope": "",
        "GameSegment": "",
        "Height": "",
        "LeagueID": "00",
        "Location": "",
        "Outcome": "",
        "PORound": "",
        "PlayerExperience": "",
        "PlayerPosition": "",
        "SeasonSegment": "",
        "ShotClockRange": "",
        "StarterBench": "",
        "TeamID": "",
        "TwoWay": "",
        "VsConference": "",
        "VsDivision": "",
        "Weight": "",
    }

    print(f"Fetching stats for season {season}...")
    try:
        response = session.get(
            url,
            headers=HEADERS,
            params=params,
            timeout=30
        )
        response.raise_for_status()
        data = json.loads(response.content)

        result_sets = data.get("resultSets", [])
        if not result_sets:
            return {}

        result_set = result_sets[0]
        headers = result_set.get("headers", [])
        rows = result_set.get("rowSet", [])

        stats_by_player = {}

        # Stats we want to keep
        # FGM, FGA, 3PM, 3PA, FTM, FTA, OREB, DREB, AST, STL, BLK, TOV, PF, PTS, GP, MIN, DD2, TD3
        # Note: API returns FG3M, FG3A, TOV (not TO)
        target_stats = {
            "FGM": "FGM",
            "FGA": "FGA",
            "FG3M": "3PM",
            "FG3A": "3PA",
            "FTM": "FTM",
            "FTA": "FTA",
            "OREB": "OREB",
            "DREB": "DREB",
            "AST": "AST",
            "STL": "STL",
            "BLK": "BLK",
            "TOV": "TOV",
            "PF": "PF",
            "PTS": "PTS",
            "GP": "GP",
            "MIN": "MIN",
            "DD2": "DD2",
            "TD3": "TD3"
        }

        for row in rows:
            player_dict = dict(zip(headers, row))
            player_id = str(player_dict.get("PLAYER_ID"))

            stats = {}
            for api_key, target_key in target_stats.items():
                val = player_dict.get(api_key, 0)
                # Convert to int if possible, otherwise float
                try:
                    stats[target_key] = int(val)
                except (ValueError, TypeError):
                     try:
                         stats[target_key] = float(val)
                     except (ValueError, TypeError):
                         stats[target_key] = 0

            stats_by_player[player_id] = stats

        return stats_by_player
    except Exception as e:
        print(f"Error fetching stats for {season}: {e}")
        return {}


def fetch_players():
    url = f"{BASE_URL}/playerindex"

    # Extract start year of the current season for filtering
    season_start = int(SEASON.split('-')[0])

    params = {
        "LeagueID": "00",
        "Season": SEASON,
        "Historical": "1"
    }

    print(f"Fetching players from NBA API for season {SEASON}...")

    # Create a session to reuse connection
    session = requests.Session()

    response = session.get(
        url,
        headers=HEADERS,
        params=params,
        timeout=30
    )
    response.raise_for_status()

    data = json.loads(response.content)

    # Fetch stats for previous 3 years
    # e.g. if SEASON is 2025-26, we want 2022-23, 2023-24, 2024-25
    # The API format for season is YYYY-YY

    stats_history = {}

    # Calculate previous 3 seasons
    # 2025-26 -> start 2025
    # 2024-25, 2023-24, 2022-23

    for i in range(1, 4):
        year = season_start - i
        next_year_short = str(year + 1)[-2:]
        season_str = f"{year}-{next_year_short}"

        time.sleep(3)  # Longer delay between requests
        season_stats = fetch_season_stats(season_str, session)
        stats_history[str(year)] = season_stats

    return parse_players(data, season_start, stats_history)


def parse_players(data, season_start_year, stats_history):
    result_sets = data.get("resultSets", [])

    if not result_sets:
        print("No result sets found in response")
        return []

    result_set = result_sets[0]
    headers = result_set.get("headers", [])
    rows = result_set.get("rowSet", [])

    print(f"Found {len(rows)} total historical players. Filtering for active in last 3 seasons ending {season_start_year}...")

    players = []

    # We want players who played in any of the 3 seasons leading up to the target season.
    min_to_year = season_start_year - 2

    for row in rows:
        # Create a dictionary from headers and row values
        player_dict = dict(zip(headers, row))

        # Filter by season
        from_year = int(player_dict.get("FROM_YEAR", 0))
        to_year = int(player_dict.get("TO_YEAR", 0))

        if to_year < min_to_year:
            continue

        if from_year > season_start_year:
            continue

        # Extract relevant fields
        first_name = player_dict.get("PLAYER_FIRST_NAME", "")
        last_name = player_dict.get("PLAYER_LAST_NAME", "")
        name = f"{first_name} {last_name}".strip()

        if not name:
            continue

        person_id = str(player_dict.get("PERSON_ID", ""))

        # Assemble stats object
        player_stats = {}
        for year, season_stats in stats_history.items():
            if person_id in season_stats:
                player_stats[year] = season_stats[person_id]

        # Calculate projection
        # Weights: Most recent (year-1) = 0.5, (year-2) = 0.3, (year-3) = 0.2
        weights = {
            str(season_start_year - 1): 0.5,
            str(season_start_year - 2): 0.3,
            str(season_start_year - 3): 0.2
        }

        projection = {}
        total_weight = 0.0
        weighted_sums = {}

        for year, weight in weights.items():
            if year in player_stats:
                stats = player_stats[year]
                total_weight += weight
                for key, value in stats.items():
                    current_sum = weighted_sums.get(key, 0.0)
                    weighted_sums[key] = current_sum + (value * weight)

        if total_weight > 0:
            for key, value in weighted_sums.items():
                # Normalize by total weight and round to nearest integer
                projection[key] = int(round(value / total_weight))

            player_stats["projection"] = projection

        player = {
            "external_id": person_id,
            "name": name,
            "team": player_dict.get("TEAM_ABBREVIATION"),
            "position": player_dict.get("POSITION"),
            "stats": player_stats
        }

        players.append(player)

    return players


def save_players(players):
    # Get the project root (2 levels up from scripts/plugins/)
    project_root = Path(__file__).parent.parent.parent

    # Extract start year from SEASON for the filename
    start_year = SEASON.split('-')[0]
    output_file = project_root / "priv" / "plugins" / f"nba_{start_year}_players.json"

    # Create the output directory if it doesn't exist
    output_file.parent.mkdir(parents=True, exist_ok=True)

    # Create the output structure
    output_data = {
        "players": players
    }

    # Write to file with pretty formatting
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    print(f"Saved {len(players)} players to {output_file}")


def main():
    print(f"NBA {SEASON} Player Data Builder")
    print("=" * 50)

    players = fetch_players()

    if not players:
        print("No players found")
        return 1

    save_players(players)
    print("Done!")
    return 0


if __name__ == "__main__":
    exit(main())

