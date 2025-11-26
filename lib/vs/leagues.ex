defmodule Vs.Leagues do
  import Ecto.Query, warn: false
  alias Vs.Repo
  alias Vs.League

  def list_leagues do
    League
    |> Repo.all()
  end

  def get_league!(id) do
    League
    |> Repo.get!(id)
  end

  def create_league(attrs \\ %{}) do
    %League{}
    |> League.changeset(attrs)
    |> Repo.insert()
  end

  def update_league(%League{} = league, attrs) do
    league
    |> League.changeset(attrs)
    |> Repo.update()
  end
end
