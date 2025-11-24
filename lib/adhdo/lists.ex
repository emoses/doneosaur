defmodule Adhdo.Lists do
  @moduledoc """
  The Lists context manages task lists and their associated tasks.
  """

  alias Adhdo.Repo
  alias Adhdo.Lists.{TaskList, Task}

  ## TaskList functions

  @doc """
  Returns the list of all task lists.
  Preloads tasks for each list.
  """
  def list_task_lists do
    TaskList
    |> Repo.all()
    |> Repo.preload(:tasks)
  end

  @doc """
  Gets a single task list by ID.
  Preloads tasks ordered by their order field.
  """
  def get_task_list!(id) do
    Repo.get!(TaskList, id)
    |> Repo.preload(:tasks)
  end

  @doc """
  Gets a task list by name.
  Preloads tasks ordered by their order field.
  """
  def get_task_list_by_name(name) do
    Repo.get_by(TaskList, name: name)
    |> case do
      nil -> nil
      task_list -> Repo.preload(task_list, :tasks)
    end
  end

  @doc """
  Creates a task list.
  """
  def create_task_list(attrs \\ %{}) do
    %TaskList{}
    |> TaskList.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task list.
  """
  def update_task_list(%TaskList{} = task_list, attrs) do
    task_list
    |> TaskList.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task list.
  """
  def delete_task_list(%TaskList{} = task_list) do
    Repo.delete(task_list)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task list changes.
  """
  def change_task_list(%TaskList{} = task_list, attrs \\ %{}) do
    TaskList.changeset(task_list, attrs)
  end

  ## Task functions

  @doc """
  Gets a single task by ID.
  """
  def get_task!(id) do
    Repo.get!(Task, id)
  end

  @doc """
  Creates a task.
  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.
  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task.
  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.
  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  @doc """
  Creates a task list with tasks in one transaction.
  Tasks are automatically assigned order numbers based on their position in the list.

  Example:
      create_task_list_with_tasks(%{
        name: "Morning Routine",
        description: "Tasks for weekday mornings",
        tasks: [
          %{text: "Get dressed"},
          %{text: "Feed cat"},
          %{text: "Eat breakfast"}
        ]
      })
  """
  def create_task_list_with_tasks(attrs) do
    Repo.transaction(fn ->
      {task_attrs, list_attrs} = Map.pop(attrs, :tasks, [])

      with {:ok, task_list} <- create_task_list(list_attrs) do
        tasks =
          task_attrs
          |> Enum.with_index(1)
          |> Enum.map(fn {task_attr, order} ->
            task_attr
            |> Map.put(:order, order)
            |> Map.put(:task_list_id, task_list.id)
            |> then(fn attrs ->
              case create_task(attrs) do
                {:ok, task} -> task
                {:error, changeset} -> Repo.rollback(changeset)
              end
            end)
          end)

        %{task_list | tasks: tasks}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end
end
