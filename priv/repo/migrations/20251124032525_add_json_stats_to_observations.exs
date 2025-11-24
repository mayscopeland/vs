defmodule Vs.Repo.Migrations.AddJsonStatsToObservations do
  use Ecto.Migration

  def change do
    alter table(:observations) do
      add :stats, :map, default: "{}"
      remove :metric
      remove :value
    end

    # Drop old index if it exists (assuming one existed for scorer/date/metric)
    # create unique_index(:observations, [:scorer_id, :game_date, :metric])

    # Create new unique index for scorer/date
    create unique_index(:observations, [:scorer_id, :game_date],
             name: :observations_scorer_id_game_date_index
           )
  end
end
