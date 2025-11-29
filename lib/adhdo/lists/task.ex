defmodule Adhdo.Lists.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :text, :string
    field :order, :integer

    belongs_to :task_list, Adhdo.Lists.TaskList

    belongs_to :image, Adhdo.Lists.Image,
      foreign_key: :image_id,
      references: :uuid,
      type: Ecto.UUID

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:text, :order, :image_id, :task_list_id])
    |> validate_required([:text, :order, :task_list_id])
    |> unique_constraint([:task_list_id, :order])
  end
end
