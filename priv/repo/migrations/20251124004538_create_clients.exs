defmodule Adhdo.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:clients, [:name])
  end
end
