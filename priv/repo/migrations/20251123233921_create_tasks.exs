defmodule Doneosaur.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :text, :string, null: false
      add :order, :integer, null: false
      add :image_url, :string
      add :task_list_id, references(:task_lists, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:tasks, [:task_list_id])
    create unique_index(:tasks, [:task_list_id, :order])
  end
end
