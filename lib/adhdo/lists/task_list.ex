defmodule Adhdo.Lists.TaskList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_lists" do
    field :name, :string
    field :description, :string

    has_many :tasks, Adhdo.Lists.Task, preload_order: [asc: :order]

    timestamps()
  end

  def changeset(task_list, attrs) do
    task_list
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
