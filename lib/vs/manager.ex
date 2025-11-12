defmodule Vs.Manager do
  use Ecto.Schema
  import Ecto.Changeset

  schema "managers" do
    field :is_commissioner, :boolean, default: false
    field :user_id, :id

    belongs_to :team, Vs.Team

    timestamps()
  end

  @doc false
  def changeset(manager, attrs) do
    manager
    |> cast(attrs, [:is_commissioner, :user_id, :team_id])
    |> validate_required([:team_id])
    |> foreign_key_constraint(:team_id)
    |> foreign_key_constraint(:user_id)
  end
end
