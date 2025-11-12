defmodule Vs.Repo.Migrations.CreateRosterPositions do
  use Ecto.Migration

  def change do
    create table(:roster_positions) do
      add :position, :string, null: false
      add :sub_positions, :string
      add :group, :string
      add :count, :integer, null: false
      add :sequence, :integer, null: false
      add :league_id, references(:leagues, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:roster_positions, [:league_id])
  end
end
