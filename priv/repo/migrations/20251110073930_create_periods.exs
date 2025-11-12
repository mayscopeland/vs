defmodule Vs.Repo.Migrations.CreatePeriods do
  use Ecto.Migration

  def change do
    create table(:periods) do
      add :name, :string, null: false
      add :sequence, :integer, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :is_playoff, :boolean, default: false, null: false
      add :league_id, references(:leagues, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:periods, [:league_id])
    create index(:periods, [:start_date])
    create index(:periods, [:end_date])
  end
end
