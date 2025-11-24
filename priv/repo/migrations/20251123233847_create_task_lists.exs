defmodule Adhdo.Repo.Migrations.CreateTaskLists do
  use Ecto.Migration

  def change do
    create table(:task_lists) do
      add :name, :string, null: false
      add :description, :text

      timestamps()
    end

    create unique_index(:task_lists, [:name])
  end
end
