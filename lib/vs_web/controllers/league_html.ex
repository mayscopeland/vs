defmodule VsWeb.LeagueHTML do
  @moduledoc """
  This module contains pages rendered by LeagueController.
  """
  use VsWeb, :html

  embed_templates "league_html/*"
end
