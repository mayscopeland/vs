defmodule Vs.Scorer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scorers" do
    field :name, :string
    field :team, :string
    field :position, :string
    field :contest_type, :string

    has_many :observations, Vs.Observation
    has_many :roster_scorers, Vs.RosterScorer

    timestamps()
  end

  @doc false
  def changeset(scorer, attrs) do
    scorer
    |> cast(attrs, [:name, :team, :position, :contest_type])
    |> validate_required([:name, :contest_type])
  end
end
