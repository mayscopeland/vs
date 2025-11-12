defmodule Vs.Repo.Migrations.CreateRosterScorers do
  use Ecto.Migration

  def change do
    create table(:roster_scorers) do
      add :roster_id, references(:rosters, on_delete: :delete_all), null: false
      add :scorer_id, references(:scorers, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:roster_scorers, [:roster_id])
    create index(:roster_scorers, [:scorer_id])
    create unique_index(:roster_scorers, [:roster_id, :scorer_id])
  end
end
