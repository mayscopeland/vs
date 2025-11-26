defmodule VsWeb.Plugs.SeasonContext do
  @moduledoc """
  Plug that loads all seasons into the connection assigns for sidebar navigation.
  """
  import Plug.Conn
  alias Vs.Seasons

  def init(opts), do: opts

  def call(conn, _opts) do
    # Fetch all seasons ordered by season year (desc) and name
    all_seasons = Seasons.list_seasons()

    # Assign to conn for use in templates
    assign(conn, :user_seasons, all_seasons)
  end
end
