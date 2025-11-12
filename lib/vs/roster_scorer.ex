defmodule Vs.RosterScorer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roster_scorers" do
    belongs_to :roster, Vs.Roster
    belongs_to :scorer, Vs.Scorer

    timestamps()
  end

  @doc false
  def changeset(roster_scorer, attrs) do
    roster_scorer
    |> cast(attrs, [:roster_id, :scorer_id])
    |> validate_required([:roster_id, :scorer_id])
    |> foreign_key_constraint(:roster_id)
    |> foreign_key_constraint(:scorer_id)
    |> unique_constraint([:roster_id, :scorer_id], name: :roster_scorers_roster_id_scorer_id_index)
  end
end
