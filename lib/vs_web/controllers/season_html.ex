defmodule VsWeb.SeasonHTML do
  @moduledoc """
  This module contains pages rendered by SeasonController.
  """
  use VsWeb, :html

  embed_templates "season_html/*"
end
