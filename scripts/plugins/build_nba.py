
import json
import gzip
import requests
from pathlib import Path

BASE_URL = "https://stats.nba.com/stats"
SEASON = "2025-26"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36",
    "Accept": "*/*",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Referer": "https://www.nba.com/",
    "Origin": "https://www.nba.com",
    "Connection": "keep-alive",
    "DNT": "1",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-site",
    "sec-ch-ua": '"Google Chrome";v="141", "Not?A_Brand";v="8", "Chromium";v="141"',
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": '"Windows"',
}


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

    response = requests.get(
        url,
        headers=HEADERS,
        params=params,
        timeout=30
    )
    response.raise_for_status()

    data = json.loads(response.content)

    return parse_players(data, season_start)


def parse_players(data, season_start_year):
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

        player = {
            "external_id": str(player_dict.get("PERSON_ID", "")),
            "name": name,
            "team": player_dict.get("TEAM_ABBREVIATION"),
            "position": player_dict.get("POSITION")
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

