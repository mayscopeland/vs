defmodule Vs.Repo.Migrations.AddJsonSlotsToRosters do
  use Ecto.Migration

  def change do
    alter table(:rosters) do
      add :slots, :map, default: "{}"
    end

    drop table(:roster_scorers)
  end
end
