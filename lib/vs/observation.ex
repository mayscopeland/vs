defmodule Vs.Observation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "observations" do
    field :contest_type, :string
    field :season_year, :integer
    field :stats, :map
    field :game_date, :date
    field :recorded_at, :utc_datetime

    belongs_to :scorer, Vs.Scorer

    timestamps()
  end

  @doc false
  def changeset(observation, attrs) do
    observation
    |> cast(attrs, [:contest_type, :season_year, :stats, :game_date, :recorded_at, :scorer_id])
    |> validate_required([:contest_type, :season_year, :stats, :game_date, :scorer_id])
    |> foreign_key_constraint(:scorer_id)
    |> unique_constraint([:scorer_id, :game_date], name: :observations_scorer_id_game_date_index)
  end
end
