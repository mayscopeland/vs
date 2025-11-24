defmodule Vs.Scorer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scorers" do
    field :name, :string
    field :team, :string
    field :position, :string
    field :contest_type, :string
    field :external_id, :string

    belongs_to :universe, Vs.Universe
    has_many :observations, Vs.Observation

    timestamps()
  end

  @doc false
  def changeset(scorer, attrs) do
    scorer
    |> cast(attrs, [:name, :team, :position, :contest_type, :external_id, :universe_id])
    |> validate_required([:name, :contest_type, :universe_id])
    |> foreign_key_constraint(:universe_id)
  end
end
