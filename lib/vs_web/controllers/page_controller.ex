defmodule VsWeb.PageController do
  use VsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
