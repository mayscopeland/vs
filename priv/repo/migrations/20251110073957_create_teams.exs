defmodule Vs.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :league_id, references(:leagues, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:teams, [:league_id])
  end
end
