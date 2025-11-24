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
    roster_positions = Leagues.get_active_roster_positions(league)

    # Build position groups structure
    position_groups = Teams.build_position_groups(roster_positions, roster, league)

    # Get scoring categories (will implement later when showing scores)
    # scoring_categories = Leagues.list_scoring_categories_for_league(league_id)

    render(conn, :show,
      page_title: "#{league.name} - #{team.name}",
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

    color_schemes = Vs.Team.ColorSchemes.all()
    font_styles = Vs.Team.FontStyles.all()

    render(conn, :edit,
      league: league,
      team: team,
      current_period: current_period,
      roster: roster,
      color_schemes: color_schemes,
      font_styles: font_styles
    )
  end

  def update(conn, %{"league_id" => league_id, "id" => team_id, "team" => team_params}) do
    team = Teams.get_team!(team_id)

    case Teams.update_team(team, team_params) do
      {:ok, _team} ->
        conn
        |> put_flash(:info, "Team updated successfully!")
        |> redirect(to: ~p"/leagues/#{league_id}/teams/#{team_id}")

      {:error, %Ecto.Changeset{} = changeset} ->
        league = Leagues.get_league!(league_id)
        current_period = Teams.current_period_for_league(league_id)

        roster =
          if current_period do
            Teams.get_roster_for_team(team_id, current_period.id)
          else
            nil
          end

        color_schemes = Vs.Team.ColorSchemes.all()
        font_styles = Vs.Team.FontStyles.all()

        render(conn, :edit,
          league: league,
          team: team,
          current_period: current_period,
          roster: roster,
          color_schemes: color_schemes,
          font_styles: font_styles,
          changeset: changeset
        )
    end
  end
end
