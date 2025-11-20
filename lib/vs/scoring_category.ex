defmodule Vs.ScoringCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scoring_categories" do
    field :name, :string
    field :formula, :string
    field :format, :string, default: "integer"
    field :multiplier, :float, default: 1.0
    field :group, :string
    field :sequence, :integer

    belongs_to :league, Vs.League

    timestamps()
  end

  @doc false
  def changeset(scoring_category, attrs) do
    scoring_category
    |> cast(attrs, [:name, :formula, :format, :multiplier, :group, :sequence, :league_id])
    |> validate_required([:name, :sequence, :league_id])
    |> foreign_key_constraint(:league_id)
  end
end
