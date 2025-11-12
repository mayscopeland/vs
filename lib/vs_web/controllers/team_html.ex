defmodule VsWeb.TeamHTML do
  @moduledoc """
  This module contains pages rendered by TeamController.
  """
  use VsWeb, :html

  embed_templates "team_html/*"
end
