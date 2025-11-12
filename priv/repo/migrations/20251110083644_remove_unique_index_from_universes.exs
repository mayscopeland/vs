defmodule Vs.Repo.Migrations.RemoveUniqueIndexFromUniverses do
  use Ecto.Migration

  def change do
    drop unique_index(:universes, [:contest_type])
  end
end
