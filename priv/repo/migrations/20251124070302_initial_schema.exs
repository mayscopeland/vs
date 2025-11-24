defmodule Vs.Repo.Migrations.InitialSchema do
  use Ecto.Migration

  def change do
    create table(:universes) do
      add :contest_type, :string, null: false
      timestamps()
    end

    create table(:users) do
      add :email, :string, null: false
      add :display_name, :string, null: false
      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:leagues) do
      add :season_year, :integer, null: false
      add :name, :string, null: false
      add :scoring_settings, :map
      add :roster_settings, :map
      add :universe_id, references(:universes, on_delete: :nothing), null: false
      timestamps()
    end

    create index(:leagues, [:universe_id])

    create table(:scorers) do
      add :name, :string, null: false
      add :team, :string
      add :position, :string
      add :contest_type, :string, null: false
      add :external_id, :string
      add :stats, :map, default: %{}
      add :universe_id, references(:universes, on_delete: :nothing), null: false
      timestamps()
    end

    create index(:scorers, [:universe_id])

    create table(:periods) do
      add :name, :string, null: false
      add :sequence, :integer, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :is_playoff, :boolean, default: false, null: false
      add :league_id, references(:leagues, on_delete: :nothing), null: false
      timestamps()
    end

    create index(:periods, [:league_id])

    create table(:teams) do
      add :name, :string, null: false
      add :color_scheme_id, :string
      add :font_style, :string
      add :league_id, references(:leagues, on_delete: :nothing), null: false
      timestamps()
    end

    create index(:teams, [:league_id])

    create table(:managers) do
      add :is_commissioner, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nothing)
      add :team_id, references(:teams, on_delete: :nothing), null: false
      timestamps()
    end

    create index(:managers, [:user_id])
    create index(:managers, [:team_id])

    create table(:rosters) do
      add :locked_at, :utc_datetime
      add :slots, :map
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :period_id, references(:periods, on_delete: :nothing), null: false
      timestamps()
    end

    create index(:rosters, [:team_id])
    create index(:rosters, [:period_id])
    create unique_index(:rosters, [:team_id, :period_id])

    create table(:observations) do
      add :contest_type, :string, null: false
      add :season_year, :integer, null: false
      add :stats, :map, null: false
      add :game_date, :date, null: false
      add :recorded_at, :utc_datetime
      add :scorer_id, references(:scorers, on_delete: :nothing), null: false
      timestamps()
    end

    create index(:observations, [:scorer_id])
    create unique_index(:observations, [:scorer_id, :game_date])
  end
end
