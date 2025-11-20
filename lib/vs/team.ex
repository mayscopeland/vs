defmodule Vs.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :color_scheme_id, :string

    belongs_to :league, Vs.League

    has_many :rosters, Vs.Roster
    has_many :managers, Vs.Manager

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :league_id, :color_scheme_id])
    |> validate_required([:name, :league_id])
    |> foreign_key_constraint(:league_id)
  end
end
