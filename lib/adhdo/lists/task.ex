defmodule Adhdo.Lists.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :text, :string
    field :order, :integer
    field :image_url, :string

    belongs_to :task_list, Adhdo.Lists.TaskList

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:text, :order, :image_url, :task_list_id])
    |> validate_required([:text, :order, :task_list_id])
    |> unique_constraint([:task_list_id, :order])
  end
end
