defmodule Vs.League do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leagues" do
    field :season_year, :integer
    field :name, :string
    field :scoring_settings, :map
    field :roster_settings, :map

    belongs_to :universe, Vs.Universe

    has_many :teams, Vs.Team
    has_many :periods, Vs.Period

    timestamps()
  end

  @doc false
  def changeset(league, attrs) do
    league
    |> cast(attrs, [:season_year, :name, :universe_id, :scoring_settings, :roster_settings])
    |> validate_required([:season_year, :name, :universe_id])
    |> foreign_key_constraint(:universe_id)
  end
end
