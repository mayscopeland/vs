defmodule VsWeb.TeamController do
  use VsWeb, :controller

  alias Vs.{Leagues, Teams}

  def redirect_to_team(conn, %{"league_id" => league_id}) do
    # Get first team in the league (later will redirect to user's team)
    teams = Teams.list_teams_for_league(league_id)

    case teams do
      [team | _] ->
        redirect(conn, to: ~p"/leagues/#{league_id}/teams/#{team.id}")

      [] ->
        conn
        |> put_flash(:error, "No teams found in this league")
        |> redirect(to: ~p"/leagues/#{league_id}")
    end
  end

  def show(conn, %{"league_id" => league_id, "id" => team_id}) do
    league = Leagues.get_league!(league_id)
    team = Teams.get_team!(team_id)
    all_teams = Teams.list_teams_for_league(league_id)

    # Get current period
    current_period = Teams.current_period_for_league(league_id)

    # Get roster for current period
    roster =
      if current_period do
        Teams.get_roster_for_team(team_id, current_period.id)
      else
        nil
      end

    # Get roster positions for league
    roster_positions = Teams.list_roster_positions_for_league(league_id)

    # Build position groups structure
    position_groups = Teams.build_position_groups(roster_positions, roster, league)

    # Get scoring categories (will implement later when showing scores)
    # scoring_categories = Leagues.list_scoring_categories_for_league(league_id)

    render(conn, :show,
      league: league,
      team: team,
      all_teams: all_teams,
      current_period: current_period,
      roster: roster,
      position_groups: position_groups
    )
  end

  def edit(conn, %{"league_id" => league_id, "id" => team_id}) do
    league = Leagues.get_league!(league_id)
    team = Teams.get_team!(team_id)

    # Get current period
    current_period = Teams.current_period_for_league(league_id)

    # Get roster for current period
    roster =
      if current_period do
        Teams.get_roster_for_team(team_id, current_period.id)
      else
        nil
      end

    render(conn, :edit,
      league: league,
      team: team,
      current_period: current_period,
      roster: roster
    )
  end

  def update(conn, %{"league_id" => league_id, "id" => team_id} = _params) do
    # TODO: Implement roster update logic
    # This will handle adding/removing players from the roster

    conn
    |> put_flash(:info, "Roster updated successfully!")
    |> redirect(to: ~p"/leagues/#{league_id}/teams/#{team_id}")
  end
end
