defmodule Vs.Repo.Migrations.AllowNullFormulaInScoringCategories do
  use Ecto.Migration

  def up do
    # SQLite doesn't support ALTER COLUMN, so we need to recreate the table
    execute """
    CREATE TABLE scoring_categories_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      formula TEXT,
      multiplier REAL DEFAULT 1.0,
      "group" TEXT,
      sequence INTEGER NOT NULL,
      league_id INTEGER NOT NULL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE CASCADE
    )
    """

    execute """
    INSERT INTO scoring_categories_new
    SELECT id, name, formula, multiplier, "group", sequence, league_id, inserted_at, updated_at
    FROM scoring_categories
    """

    execute "DROP TABLE scoring_categories"
    execute "ALTER TABLE scoring_categories_new RENAME TO scoring_categories"

    create index(:scoring_categories, [:league_id])
  end

  def down do
    # Reverting would require making formula NOT NULL again
    # Since we don't have data yet, this is acceptable
    execute """
    CREATE TABLE scoring_categories_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      formula TEXT NOT NULL,
      multiplier REAL DEFAULT 1.0,
      "group" TEXT,
      sequence INTEGER NOT NULL,
      league_id INTEGER NOT NULL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (league_id) REFERENCES leagues(id) ON DELETE CASCADE
    )
    """

    execute """
    INSERT INTO scoring_categories_new
    SELECT id, name, formula, multiplier, "group", sequence, league_id, inserted_at, updated_at
    FROM scoring_categories
    """

    execute "DROP TABLE scoring_categories"
    execute "ALTER TABLE scoring_categories_new RENAME TO scoring_categories"

    create index(:scoring_categories, [:league_id])
  end
end
