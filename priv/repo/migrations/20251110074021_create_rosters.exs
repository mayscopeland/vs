defmodule Vs.Repo.Migrations.CreateRosters do
  use Ecto.Migration

  def change do
    create table(:rosters) do
      add :locked_at, :utc_datetime
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :period_id, references(:periods, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:rosters, [:team_id])
    create index(:rosters, [:period_id])
    create unique_index(:rosters, [:team_id, :period_id])
  end
end
