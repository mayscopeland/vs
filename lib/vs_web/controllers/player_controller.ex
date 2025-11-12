defmodule VsWeb.PlayerController do
  use VsWeb, :controller

  alias Vs.{Leagues, Players}

  def list(conn, %{"league_id" => league_id}) do
    league = Leagues.get_league!(league_id)
    players = Players.list_available_players(league_id)

    render(conn, :list, league: league, players: players)
  end
end
