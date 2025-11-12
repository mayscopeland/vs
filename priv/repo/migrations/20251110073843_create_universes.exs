defmodule Vs.Repo.Migrations.CreateUniverses do
  use Ecto.Migration

  def change do
    create table(:universes) do
      add :contest_type, :string, null: false

      timestamps()
    end

    create unique_index(:universes, [:contest_type])
  end
end
