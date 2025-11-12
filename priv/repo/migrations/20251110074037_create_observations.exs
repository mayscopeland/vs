defmodule Vs.Repo.Migrations.CreateObservations do
  use Ecto.Migration

  def change do
    create table(:observations) do
      add :contest_type, :string, null: false
      add :season_year, :integer, null: false
      add :metric, :string, null: false
      add :value, :integer, null: false
      add :game_date, :date, null: false
      add :recorded_at, :utc_datetime
      add :scorer_id, references(:scorers, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:observations, [:scorer_id])
    create index(:observations, [:contest_type])
    create index(:observations, [:season_year])
    create index(:observations, [:game_date])
  end
end
