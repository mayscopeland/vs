defmodule Vs.Repo.Migrations.CreateScoringCategories do
  use Ecto.Migration

  def change do
    create table(:scoring_categories) do
      add :name, :string, null: false
      add :formula, :string, null: false
      add :multiplier, :float, default: 1.0, null: false
      add :group, :string
      add :sequence, :integer, null: false
      add :league_id, references(:leagues, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:scoring_categories, [:league_id])
  end
end
