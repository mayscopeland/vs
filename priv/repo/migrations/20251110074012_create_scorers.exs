defmodule Vs.Repo.Migrations.CreateScorers do
  use Ecto.Migration

  def change do
    create table(:scorers) do
      add :name, :string, null: false
      add :team, :string
      add :position, :string
      add :contest_type, :string, null: false

      timestamps()
    end

    create index(:scorers, [:contest_type])
    create index(:scorers, [:name])
  end
end
