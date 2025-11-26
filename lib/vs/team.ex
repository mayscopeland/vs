defmodule Vs.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :color_scheme_id, :string
    field :font_style, :string

    belongs_to :season, Vs.Season

    has_many :rosters, Vs.Roster
    has_many :managers, Vs.Manager

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :season_id, :color_scheme_id, :font_style])
    |> validate_required([:name, :season_id])
    |> foreign_key_constraint(:season_id)
  end
end
