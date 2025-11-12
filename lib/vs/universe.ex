defmodule Vs.Universe do
  use Ecto.Schema
  import Ecto.Changeset

  schema "universes" do
    field :contest_type, :string

    has_many :leagues, Vs.League

    timestamps()
  end

  @doc false
  def changeset(universe, attrs) do
    universe
    |> cast(attrs, [:contest_type])
    |> validate_required([:contest_type])
  end
end
