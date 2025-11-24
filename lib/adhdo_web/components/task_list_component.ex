defmodule AdhdoWeb.TaskListComponent do
  @moduledoc """
  LiveComponent for displaying and managing a task list session.
  Handles starting the session, subscribing to updates, and rendering the task list.
  """
  use AdhdoWeb, :live_component

  alias Adhdo.{Lists, Sessions}

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{list_id: list_id} = _assigns, socket) do
    case Lists.get_task_list!(list_id) do
      nil ->
        {:ok, assign(socket, :task_list, nil)}

      task_list ->
        # Start a session for this list if it doesn't exist
        Sessions.start_session(list_id)

        # Subscribe to updates if connected
        if connected?(socket) do
          Sessions.subscribe(list_id)
        end

        # Get current completion state
        completed_tasks = Sessions.get_completed_tasks(list_id)

        {:ok,
         socket
         |> assign(:task_list, task_list)
         |> assign(:completed_tasks, completed_tasks)
         |> assign(:list_id, list_id)}
    end
  end

  @impl true
  def handle_event("toggle_task", %{"task-id" => task_id}, socket) do
    task_id = String.to_integer(task_id)
    list_id = socket.assigns.list_id

    {:ok, _completed?} = Sessions.toggle_task(list_id, task_id)

    {:noreply, socket}
  end

  def handle_info({:updated, _}, socket) do
    completed_tasks = Sessions.get_completed_tasks(socket.assigns.list_id)

    {:noreply, assign(socket, :completed_tasks, completed_tasks)}
  end

  @impl true
  def render(assigns) do
    if assigns[:task_list] do
      render_task_list(assigns)
    else
      render_not_found(assigns)
    end
  end

  defp render_not_found(assigns) do
    ~H"""
    <div class="waiting-container">
      <p class="waiting-message">Task list not found</p>
    </div>
    """
  end

  defp render_task_list(assigns) do
    task_count = length(assigns.task_list.tasks)
    has_description = assigns.task_list.description != nil

    gap_size = 1
    header_height = if has_description, do: 16, else: 12
    available_height = 100 - header_height - gap_size * task_count - 8
    task_height = available_height / task_count

    assigns = assign(assigns, task_height: task_height)

    ~H"""
    <div class="container">
      <div class="header">
        <h1 class="title">{@task_list.name}</h1>
        <p :if={@task_list.description} class="description">{@task_list.description}</p>
      </div>

      <div class="tasks-container" style={"--task-height: #{@task_height}"}>
        <div
          :for={task <- @task_list.tasks}
          class={"task-item #{if MapSet.member?(@completed_tasks, task.id), do: "completed", else: ""}"}
          phx-click="toggle_task"
          phx-value-task-id={task.id}
          phx-target={@myself}
        >
          <input
            type="checkbox"
            id={"task-#{task.id}"}
            checked={MapSet.member?(@completed_tasks, task.id)}
            phx-click="toggle_task"
            phx-value-task-id={task.id}
            phx-target={@myself}
            class="task-checkbox"
          />
          <label
            for={"task-#{task.id}"}
            class="task-label"
          >
            {task.text}
          </label>
        </div>
      </div>
    </div>
    """
  end
end
