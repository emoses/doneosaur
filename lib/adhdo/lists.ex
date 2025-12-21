defmodule Adhdo.Lists do
  @moduledoc """
  The Lists context manages task lists and their associated tasks.
  """

  import Ecto.Query

  alias Adhdo.Repo
  alias Adhdo.Lists.{TaskList, Task, Image, Schedule}

  def schedules_query, do: from(s in Schedule, order_by: [asc: s.day_of_week, asc: s.time])

  ## TaskList functions

  @doc """
  Returns the list of all task lists.
  Preloads tasks and schedules for each list.
  Schedules are ordered by day of week, then by time.
  """
  def list_task_lists do

    TaskList
    |> Repo.all()
    |> Repo.preload(:tasks)
    |> Repo.preload(schedules: schedules_query())
  end

  @doc """
  Gets a single task list by ID.
  Preloads tasks ordered by their order field.
  """
  def get_task_list!(id) do
    Repo.get!(TaskList, id)
    |> Repo.preload([tasks: [:image]])
    |> Repo.preload(schedules: schedules_query())
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

  def update_task_list_and_tasks(task_list, attrs, task_attrs) do
    import Ecto.Query

    Repo.transaction(fn ->
      case update_task_list(task_list, attrs) do
        {:ok, updated_list} ->
          # Delete all existing tasks for this task list
          from(t in Task, where: t.task_list_id == ^updated_list.id)
          |> Repo.delete_all()

          # Insert all new tasks
          task_attrs
          |> Enum.with_index(1)
          |> Enum.each(fn {task_data, order} ->
            create_task(%{
              text: task_data.text,
              image_id: Map.get(task_data, :image_id),
              order: order,
              task_list_id: updated_list.id
            })
          end)

          updated_list

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  ## Image functions

  @doc """
  Returns the list of all images.
  """
  def list_images do
    Image
    |> Repo.all()
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Gets a single image by UUID.
  """
  def get_image!(uuid) do
    Repo.get!(Image, uuid)
  end

  @doc """
  Creates an image.
  """
  def create_image(attrs \\ %{}) do
    %Image{}
    |> Image.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes an image.
  """
  def delete_image(%Image{} = image) do
    Repo.delete(image)
  end

  @doc """
  Returns the URL path for an image based on its UUID and type.
  Uses the configured image path from application config.
  """
  def get_image_url(%Image{uuid: uuid, type: type}) do
    base_path = Application.get_env(:adhdo, :image_path, "/images/tasks")
    "#{base_path}/#{uuid}.#{type}"
  end

  def get_image_url(uuid) when is_binary(uuid) do
    get_image!(uuid) |> get_image_url()
  end

  ## Schedule functions

  @doc """
  Returns all schedules, optionally preloading task lists.
  """
  def list_schedules(preload_task_list \\ false) do
    import Ecto.Query

    query = Schedule
    |> order_by([s], [asc: s.day_of_week, asc: s.time])

    query =
      if preload_task_list do
        query |> Repo.preload(:task_list)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Returns all schedules for a specific task list.
  """
  def list_schedules_for_task_list(task_list_id) do
    import Ecto.Query

    Schedule
    |> where([s], s.task_list_id == ^task_list_id)
    |> order_by([s], [asc: s.day_of_week, asc: s.time])
    |> Repo.all()
  end

  @doc """
  Returns all schedules for a specific day of week and time.
  """
  def list_schedules_for_time(day_of_week, time) do
    import Ecto.Query

    Schedule
    |> where([s], s.day_of_week == ^day_of_week and s.time == ^time)
    |> preload(:task_list)
    |> Repo.all()
  end

  @doc """
  Gets a single schedule by ID.
  """
  def get_schedule!(id) do
    Repo.get!(Schedule, id)
  end

  @doc """
  Creates a schedule.
  Notifies the scheduler to reload.
  """
  def create_schedule(attrs \\ %{}) do
    result =
      %Schedule{}
      |> Schedule.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, _schedule} -> notify_scheduler_reload()
      _ -> :ok
    end

    result
  end

  def create_schedules(attrs_list) do
    result =
      Repo.transaction(fn ->
        Enum.map(attrs_list, fn attrs ->
          case %Schedule{} |> Schedule.changeset(attrs) |> Repo.insert() do
            {:ok, schedule} -> schedule
            {:error, changeset} -> Repo.rollback(changeset)
          end
        end)
      end)

    case result do
      {:ok, _schedules} -> notify_scheduler_reload()
      _ -> :ok
    end

    result
  end

  @doc """
  Deletes a schedule.
  Notifies the scheduler to reload.
  """
  def delete_schedule(%Schedule{} = schedule) do
    result = Repo.delete(schedule)

    case result do
      {:ok, _schedule} -> notify_scheduler_reload()
      _ -> :ok
    end

    result
  end

  def delete_schedule(schedule_id) when is_integer(schedule_id), do: delete_schedule(%Schedule{id: schedule_id})

  @doc """
  Deletes all schedules for a specific task list.
  Useful when replacing all schedules at once.
  """
  def delete_schedules_for_task_list(task_list_id) do
    import Ecto.Query

    Schedule
    |> where([s], s.task_list_id == ^task_list_id)
    |> Repo.delete_all()
  end

  @doc """
  Replaces all schedules for a task list with new ones.
  Takes a list of schedule attributes (without task_list_id).
  Notifies the scheduler to reload.

  Example:
      set_schedules_for_task_list(task_list.id, [
        %{day_of_week: 1, time: ~T[07:30:00]},
        %{day_of_week: 2, time: ~T[07:30:00]},
        %{day_of_week: 5, time: ~T[16:00:00]}
      ])
  """
  def set_schedules_for_task_list(task_list_id, schedule_attrs_list) do
    result =
      Repo.transaction(fn ->
        # Delete existing schedules
        delete_schedules_for_task_list(task_list_id)

        # Insert new schedules (using internal create without notification)
        schedules =
          Enum.map(schedule_attrs_list, fn attrs ->
            attrs = Map.put(attrs, :task_list_id, task_list_id)

            case %Schedule{} |> Schedule.changeset(attrs) |> Repo.insert() do
              {:ok, schedule} -> schedule
              {:error, changeset} -> Repo.rollback(changeset)
            end
          end)

        schedules
      end)

    # Notify scheduler after transaction completes
    case result do
      {:ok, _schedules} -> notify_scheduler_reload()
      _ -> :ok
    end

    result
  end

  # Private helper to notify scheduler of changes
  defp notify_scheduler_reload do
    try do
      Adhdo.Scheduler.reload()
    catch
      :exit, _ -> :ok
    end
  end
end
