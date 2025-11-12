defmodule Vs.Repo.Migrations.CreateLeagues do
  use Ecto.Migration

  def change do
    create table(:leagues) do
      add :season_year, :integer, null: false
      add :name, :string, null: false
      add :universe_id, references(:universes, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:leagues, [:universe_id])
    create index(:leagues, [:season_year])
  end
end
