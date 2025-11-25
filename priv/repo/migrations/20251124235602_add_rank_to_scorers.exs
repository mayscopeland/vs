defmodule Vs.Repo.Migrations.AddRankToScorers do
  use Ecto.Migration

  def change do
    alter table(:scorers) do
      add :rank, :map, default: %{}
    end
  end
end
