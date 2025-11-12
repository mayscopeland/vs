defmodule VsWeb.Plugs.LeagueContext do
  @moduledoc """
  Plug that loads all leagues into the connection assigns for sidebar navigation.
  """
  import Plug.Conn
  alias Vs.Leagues

  def init(opts), do: opts

  def call(conn, _opts) do
    # Fetch all leagues ordered by season year (desc) and name
    all_leagues = Leagues.list_leagues()

    # Assign to conn for use in templates
    assign(conn, :user_leagues, all_leagues)
  end
end
