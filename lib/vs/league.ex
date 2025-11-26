defmodule Vs.League do
  use Ecto.Schema
  import Ecto.Changeset

  schema "leagues" do
    field :contest_type, :string

    has_many :seasons, Vs.Season
    has_many :scorers, Vs.Scorer

    timestamps()
  end

  @doc false
  def changeset(league, attrs) do
    league
    |> cast(attrs, [:contest_type])
    |> validate_required([:contest_type])
  end
end
