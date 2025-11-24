defmodule AdhdoWeb.TaskListLive do
  use AdhdoWeb, :live_view

  alias Adhdo.{Lists, Sessions}

  @impl true
  def mount(%{"id" => list_id}, _session, socket) do
    list_id = String.to_integer(list_id)

    case Lists.get_task_list!(list_id) do
      nil ->
        {:ok, socket |> put_flash(:error, "Task list not found") |> redirect(to: ~p"/")}

      task_list ->
        # Start a session for this list if it doesn't exist
        Sessions.start_session(list_id)

        # Subscribe to updates
        if connected?(socket) do
          Sessions.subscribe(list_id)
        end

        # Get current completion state
        completed_tasks = Sessions.get_completed_tasks(list_id)

        {:ok,
         socket
         |> assign(:task_list, task_list)
         |> assign(:completed_tasks, completed_tasks)}
    end
  end

  @impl true
  def handle_event("toggle_task", %{"task-id" => task_id}, socket) do
    task_id = String.to_integer(task_id)
    list_id = socket.assigns.task_list.id

    {:ok, _completed?} = Sessions.toggle_task(list_id, task_id)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:task_toggled, task_id, completed?}, socket) do
    completed_tasks =
      if completed? do
        MapSet.put(socket.assigns.completed_tasks, task_id)
      else
        MapSet.delete(socket.assigns.completed_tasks, task_id)
      end

    {:noreply, assign(socket, :completed_tasks, completed_tasks)}
  end

  @impl true
  def handle_info(:session_reset, socket) do
    {:noreply, assign(socket, :completed_tasks, MapSet.new())}
  end

  @impl true
  def render(assigns) do
    task_count = length(assigns.task_list.tasks)
    has_description = assigns.task_list.description != nil

    gap_size = 1

    # Reserve space for header: title (8vh) + description (4vh if exists) + margins (4vh)
    header_height = if has_description, do: 16, else: 12
    # Available height for tasks (subtract header and gaps, and footer padding)
    available_height = 100 - header_height - gap_size*task_count - 8
    # Height per task
    task_height = (available_height / task_count)

    # Font size: 3.5% of task height, capped at 36pt (2.25rem)
    font_size = max(task_height * 0.35, 2.25)
    # Checkbox: slightly smaller than font
    checkbox_size = min(task_height * 0.3, 2.0)
    # Padding: proportional to task height
    padding = min(task_height * 0.15, 1.0)

    assigns =
      assign(assigns, %{
        task_height: task_height,
        font_size: font_size,
        checkbox_size: checkbox_size,
        padding: padding
      })

    ~H"""
    <style>
      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        font-family: system-ui, -apple-system, sans-serif;
      }

      .container {
        height: 100vh;
        width: 100vw;
        background: linear-gradient(135deg, #e0f2fe 0%, #ddd6fe 100%);
        display: flex;
        flex-direction: column;
        padding: 2vh;
        overflow: hidden;
      }

      .header {
        text-align: center;
        margin-bottom: 2vh;
      }

      .title {
        font-size: 8vh;
        font-weight: bold;
        color: #1f2937;
        margin: 0 0 1vh 0;
      }

      .description {
        font-size: 4vh;
        color: #6b7280;
        margin: 0;
      }

      .tasks-container {
        display: flex;
        flex-direction: column;
        gap: 1vh;
        flex: 1;
        min-height: 0;
      }

      .task-item {
        display: flex;
        align-items: center;
        background: white;
        border-radius: 1rem;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        border: 4px solid transparent;
        transition: all 0.2s;
        height: <%= @task_height %>vh;
        padding: <%= @padding %>rem;
        gap: <%= @padding * 2 %>rem;
      }

      .task-item:hover {
        box-shadow: 0 10px 15px rgba(0, 0, 0, 0.15);
      }

      .task-item:active {
        transform: scale(0.98);
      }

      .task-item.completed {
        background: #f0fdf4;
        border-color: #86efac;
      }

      .task-checkbox {
        width: <%= @task_height * 0.7 %>vh;
        height: <%= @task_height * 0.7 %>vh;
        border: 3px solid #9ca3af;
        border-radius: 0.5rem;
        cursor: pointer;
        accent-color: #22c55e;
      }

      .task-checkbox:focus {
        outline: 3px solid #86efac;
        outline-offset: 2px;
      }

      .task-label {
        font-size: <%= @task_height *0.5 %>vh;
        font-weight: 500;
        cursor: pointer;
        user-select: none;
        line-height: 1.2;
        flex: 1;
        display: flex;
        align-items: center;
      }

      .task-label.completed {
        text-decoration: line-through;
        color: #9ca3af;
      }
    </style>

    <div class="container">
      <div class="header">
        <h1 class="title">{@task_list.name}</h1>
        <p :if={@task_list.description} class="description">{@task_list.description}</p>
      </div>

      <div class="tasks-container">
        <div
          :for={task <- @task_list.tasks}
          class={"task-item #{if MapSet.member?(@completed_tasks, task.id), do: "completed", else: ""}"}
        >
          <input
            type="checkbox"
            id={"task-#{task.id}"}
            checked={MapSet.member?(@completed_tasks, task.id)}
            phx-click="toggle_task"
            phx-value-task-id={task.id}
            class="task-checkbox"
          />
          <label
            for={"task-#{task.id}"}
            class={"task-label #{if MapSet.member?(@completed_tasks, task.id), do: "completed", else: ""}"}
          >
            {task.text}
          </label>
        </div>
      </div>
    </div>
    """
  end
end
