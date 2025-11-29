defmodule Adhdo.Repo.Migrations.AddImageIdToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      remove :image_url
      add :image_id, references(:images, type: :binary_id, column: :uuid, on_delete: :nilify_all)
    end

    create index(:tasks, [:image_id])
  end
end
