defmodule Vs.RosterPosition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roster_positions" do
    field :position, :string
    field :sub_positions, :string
    field :group, :string
    field :count, :integer
    field :sequence, :integer

    belongs_to :league, Vs.League

    timestamps()
  end

  @doc false
  def changeset(roster_position, attrs) do
    roster_position
    |> cast(attrs, [:position, :sub_positions, :group, :count, :sequence, :league_id])
    |> validate_required([:position, :count, :sequence, :league_id])
    |> foreign_key_constraint(:league_id)
  end
end
