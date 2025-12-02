defmodule VsWeb.TeamController do
  use VsWeb, :controller

  alias Vs.{Seasons, Teams}

  def redirect_to_team(conn, %{"season_id" => season_id}) do
    # Get first team in the season (later will redirect to user's team)
    teams = Teams.list_teams_for_season(season_id)

    case teams do
      [team | _] ->
        redirect(conn, to: ~p"/leagues/#{season_id}/teams/#{team.id}")

      [] ->
        conn
        |> put_flash(:error, "No teams found in this league")
        |> redirect(to: ~p"/leagues/#{season_id}")
    end
  end

  def show(conn, %{"season_id" => season_id, "id" => team_id}) do
    season = Seasons.get_season!(season_id)
    team = Teams.get_team!(team_id)
    all_teams = Teams.list_teams_for_season(season_id)

    # Get all periods for navigation
    periods = Teams.list_periods_for_season(season_id)

    # Determine selected period
    selected_period =
      case Map.get(conn.params, "period") do
        nil ->
          Teams.current_period_for_season(season_id) || List.first(periods)

        seq ->
          sequence = String.to_integer(seq)
          Enum.find(periods, fn p -> p.sequence == sequence end)
      end

    # Determine prev/next periods
    {prev_period, next_period} =
      if selected_period do
        index = Enum.find_index(periods, &(&1.id == selected_period.id))
        prev = if index > 0, do: Enum.at(periods, index - 1), else: nil
        next = if index < length(periods) - 1, do: Enum.at(periods, index + 1), else: nil
        {prev, next}
      else
        {nil, nil}
      end

    # Get roster for selected period
    roster =
      if selected_period do
        Teams.get_roster_for_team(team_id, selected_period.id)
      else
        nil
      end

    # Get roster positions for league
    roster_positions = Seasons.get_active_roster_positions(season)

    # Build position groups structure
    position_groups = Teams.build_position_groups(roster_positions, roster, season)

    # Get position colors from season roster settings
    position_colors =
      (season.roster_settings || [])
      |> Enum.map(fn setting ->
        # Handle string keys from JSON
        position = Map.get(setting, "position") || Map.get(setting, :position)
        color = Map.get(setting, "color") || Map.get(setting, :color)
        {position, color}
      end)
      |> Map.new()

    # Get scoring categories (will implement later when showing scores)
    # scoring_categories = Leagues.list_scoring_categories_for_league(league_id)

    render(conn, :show,
      page_title: "#{season.name} - #{team.name}",
      season: season,
      team: team,
      all_teams: all_teams,
      periods: periods,
      # Renaming to current_period for view compatibility, but it's really selected
      current_period: selected_period,
      prev_period: prev_period,
      next_period: next_period,
      roster: roster,
      position_groups: position_groups,
      position_colors: position_colors
    )
  end

  def edit(conn, %{"season_id" => season_id, "id" => team_id}) do
    season = Seasons.get_season!(season_id)
    team = Teams.get_team!(team_id)
    changeset = Teams.change_team(team)

    # Get current period
    current_period = Teams.current_period_for_season(season_id)

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
      season: season,
      team: team,
      current_period: current_period,
      roster: roster,
      color_schemes: color_schemes,
      font_styles: font_styles,
      changeset: changeset
    )
  end

  def update(conn, %{"season_id" => season_id, "id" => team_id, "team" => team_params}) do
    team = Teams.get_team!(team_id)

    case Teams.update_team(team, team_params) do
      {:ok, _team} ->
        conn
        |> put_flash(:info, "Team updated successfully!")
        |> redirect(to: ~p"/leagues/#{season_id}/teams/#{team_id}")

      {:error, %Ecto.Changeset{} = changeset} ->
        season = Seasons.get_season!(season_id)
        current_period = Teams.current_period_for_season(season_id)

        roster =
          if current_period do
            Teams.get_roster_for_team(team_id, current_period.id)
          else
            nil
          end

        color_schemes = Vs.Team.ColorSchemes.all()
        font_styles = Vs.Team.FontStyles.all()

        render(conn, :edit,
          season: season,
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
