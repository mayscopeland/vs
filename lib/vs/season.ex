defmodule Vs.Season do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seasons" do
    field :season_year, :integer
    field :name, :string
    field :scoring_type, :string
    field :scoring_settings, :map
    field :roster_settings, {:array, :map}

    belongs_to :league, Vs.League

    has_many :teams, Vs.Team
    has_many :periods, Vs.Period

    timestamps()
  end

  @doc false
  def changeset(season, attrs) do
    season
    |> cast(attrs, [
      :season_year,
      :name,
      :league_id,
      :scoring_settings,
      :roster_settings,
      :scoring_type
    ])
    |> validate_required([:season_year, :name, :league_id])
    |> foreign_key_constraint(:league_id)
  end
end
