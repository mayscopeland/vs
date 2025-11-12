defmodule VsWeb.PlayerHTML do
  @moduledoc """
  This module contains pages rendered by PlayerController.
  """
  use VsWeb, :html

  embed_templates "player_html/*"
end
