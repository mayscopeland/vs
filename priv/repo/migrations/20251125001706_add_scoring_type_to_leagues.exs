defmodule Vs.Repo.Migrations.AddScoringTypeToLeagues do
  use Ecto.Migration

  def change do
    alter table(:leagues) do
      add :scoring_type, :string, default: "points"
    end
  end
end
