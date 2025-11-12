defmodule Vs.Repo.Migrations.CreateManagers do
  use Ecto.Migration

  def change do
    create table(:managers) do
      add :is_commissioner, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nilify_all)
      add :team_id, references(:teams, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:managers, [:user_id])
    create index(:managers, [:team_id])
  end
end
