defmodule Vs.Period do
  use Ecto.Schema
  import Ecto.Changeset

  schema "periods" do
    field :name, :string
    field :sequence, :integer
    field :start_date, :date
    field :end_date, :date
    field :is_playoff, :boolean, default: false

    belongs_to :league, Vs.League

    has_many :rosters, Vs.Roster

    timestamps()
  end

  @doc false
  def changeset(period, attrs) do
    period
    |> cast(attrs, [:name, :sequence, :start_date, :end_date, :is_playoff, :league_id])
    |> validate_required([:name, :sequence, :start_date, :end_date, :league_id])
    |> foreign_key_constraint(:league_id)
  end
end
