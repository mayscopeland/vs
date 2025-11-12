defmodule Vs.Roster do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rosters" do
    field :locked_at, :utc_datetime

    belongs_to :team, Vs.Team
    belongs_to :period, Vs.Period

    has_many :roster_scorers, Vs.RosterScorer

    timestamps()
  end

  @doc false
  def changeset(roster, attrs) do
    roster
    |> cast(attrs, [:locked_at, :team_id, :period_id])
    |> validate_required([:team_id, :period_id])
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:period_id)
    |> unique_constraint([:team_id, :period_id], name: :rosters_team_id_period_id_index)
  end
end
