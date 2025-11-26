defmodule Vs.Repo.Migrations.AddScoringTypeToSeasons do
  use Ecto.Migration

  def change do
    alter table(:seasons) do
      add :scoring_type, :string, default: "points"
    end
  end
end
