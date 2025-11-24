defmodule Vs.Repo.Migrations.InitialSchema do
  use Ecto.Migration

  def change do
    create table(:universes) do
      add :contest_type, :string, null: false

      timestamps()
    end

    create table(:leagues) do
      add :season_year, :integer, null: false
      add :name, :string, null: false
      add :universe_id, references(:universes, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:teams) do
      add :name, :string, null: false
      add :color_scheme_id, :string
      add :font_style, :string
      add :league_id, references(:leagues, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:users) do
      add :email, :string, null: false
      add :display_name, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:managers) do
      add :is_commissioner, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :team_id, references(:teams, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:periods) do
      add :name, :string, null: false
      add :sequence, :integer, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :is_playoff, :boolean, default: false, null: false
      add :league_id, references(:leagues, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:rosters) do
      add :locked_at, :utc_datetime
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :period_id, references(:periods, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:rosters, [:team_id, :period_id])

    create table(:roster_positions) do
      add :position, :string, null: false
      add :sub_positions, :string
      add :group, :string
      add :count, :integer, null: false
      add :sequence, :integer, null: false
      add :league_id, references(:leagues, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:scorers) do
      add :name, :string, null: false
      add :team, :string
      add :position, :string
      add :contest_type, :string, null: false
      add :external_id, :string
      add :universe_id, references(:universes, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:roster_scorers) do
      add :roster_id, references(:rosters, on_delete: :delete_all), null: false
      add :scorer_id, references(:scorers, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:roster_scorers, [:roster_id, :scorer_id])

    create table(:scoring_categories) do
      add :name, :string, null: false
      add :formula, :string
      add :format, :string, default: "integer"
      add :multiplier, :float, default: 1.0
      add :group, :string
      add :sequence, :integer, null: false
      add :league_id, references(:leagues, on_delete: :delete_all), null: false

      timestamps()
    end

    create table(:observations) do
      add :contest_type, :string, null: false
      add :season_year, :integer, null: false
      add :metric, :string, null: false
      add :value, :integer, null: false
      add :game_date, :date, null: false
      add :recorded_at, :utc_datetime
      add :scorer_id, references(:scorers, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
