defmodule AdhdoWeb.TaskListDisplay do
  @moduledoc """
  Stateless function component for rendering task lists.
  """
  use Phoenix.Component

  alias Adhdo.Lists

  @doc """
  Renders a task list with dynamically sized tasks.

  ## Attributes
    - task_list: The task list struct with name, description, and tasks (required)
    - completed_tasks: MapSet of completed task IDs (required)
  """
  attr :task_list, :map, required: true
  attr :completed_tasks, :map, required: true

  def task_list(assigns) do
    task_count = length(assigns.task_list.tasks)
    has_description = assigns.task_list.description != nil

    gap_size = 1
    header_height = if has_description, do: 16, else: 12
    available_height = 100 - header_height - gap_size * task_count - 8
    task_height = available_height / task_count

    assigns = assign(assigns, task_height: task_height)

    ~H"""
    <div class="container">
      <header>
        <div class="content">
          <h1 class="title">{@task_list.name}</h1>
          <p :if={@task_list.description} class="description">{@task_list.description}</p>
        </div>
        <div class="controls">
          <button phx-click="reset_list">Reset</button>
        </div>
      </header>

      <div class="tasks-container" style={"--task-height: #{@task_height}"}>
        <div
          :for={task <- @task_list.tasks}
          class={"task-item #{if MapSet.member?(@completed_tasks, task.id), do: "completed", else: ""}"}
          phx-click="toggle_task"
          phx-value-task-id={task.id}
        >
          <% image_url = if task.image_id, do: Lists.get_image_url(task.image_id), else: nil %>
          <input
            type="checkbox"
            id={"task-#{task.id}"}
            checked={MapSet.member?(@completed_tasks, task.id)}
            class={"task-checkbox #{if image_url, do: "has-image", else: ""}"}
            style={if image_url, do: "background-image: url(#{image_url})", else: ""}
          />
          <label for={"task-#{task.id}"} class="task-label">
            {task.text}
          </label>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a waiting screen when no task list is available.
  """
  attr :message, :string, default: "Waiting for a task list..."
  attr :subtitle, :string, default: nil

  def waiting_screen(assigns) do
    ~H"""
    <div class="waiting-container">
      <p class="waiting-message">{@message}</p>
      <p :if={@subtitle} class="waiting-subtitle">{@subtitle}</p>
    </div>
    """
  end
end
