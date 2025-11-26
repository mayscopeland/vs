defmodule Vs.Repo.Migrations.RemovePeriodName do
  use Ecto.Migration

  def change do
    alter table(:periods) do
      remove :name
    end
  end
end
