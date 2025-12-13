defmodule Adhdo.Repo.Migrations.ScheduleTable do
  use Ecto.Migration

  def change do
    create table("task_list_schedule") do
      add :day_of_week, :integer, null: false
      add :time, :time, null: false
      add :task_list_id, references(:task_lists, on_delete: :delete_all), null: false
    end
  end
end
