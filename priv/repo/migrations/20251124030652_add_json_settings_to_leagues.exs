defmodule Vs.Repo.Migrations.AddJsonSettingsToLeagues do
  use Ecto.Migration

  def change do
    alter table(:leagues) do
      add :scoring_settings, :map, default: "{}"
      add :roster_settings, :map, default: "{}"
    end

    drop table(:scoring_categories)
    drop table(:roster_positions)
  end
end
