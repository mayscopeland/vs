defmodule Vs.Period do
  use Ecto.Schema
  import Ecto.Changeset

  schema "periods" do
    field :sequence, :integer
    field :start_date, :date
    field :end_date, :date
    field :is_playoff, :boolean, default: false

    belongs_to :season, Vs.Season

    has_many :rosters, Vs.Roster

    timestamps()
  end

  @doc false
  def changeset(period, attrs) do
    period
    |> cast(attrs, [:sequence, :start_date, :end_date, :is_playoff, :season_id])
    |> validate_required([:sequence, :start_date, :end_date, :season_id])
    |> foreign_key_constraint(:season_id)
  end
end
