defmodule AdhdoWeb.ClientLive do
  use AdhdoWeb, :live_view

  alias Adhdo.{Clients, Lists, Sessions}

  @impl true
  def mount(%{"name" => client_name}, _session, socket) do
    # Ensure client exists
    {:ok, _client} = Clients.get_or_create_client(client_name)

    # Check for active list
    case Sessions.get_active_list_for_client(client_name) do
      nil ->
        # No active list, show waiting screen
        {:ok,
         socket
         |> assign(:client_name, client_name)
         |> assign(:active_list, nil)
         |> assign(:task_list, nil)
         |> assign(:completed_tasks, MapSet.new())}

      list_id ->
        # Has active list, load it and subscribe
        task_list = Lists.get_task_list!(list_id)

        if connected?(socket) do
          Sessions.subscribe(list_id)
        end

        completed_tasks = Sessions.get_completed_tasks(list_id)

        {:ok,
         socket
         |> assign(:client_name, client_name)
         |> assign(:active_list, list_id)
         |> assign(:task_list, task_list)
         |> assign(:completed_tasks, completed_tasks)}
    end
  end

  @impl true
  def handle_event("toggle_task", %{"task-id" => task_id}, socket) do
    task_id = String.to_integer(task_id)
    list_id = socket.assigns.active_list

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
    ~H"""
    <%= if @task_list do %>
      <%= render_task_list(assigns) %>
    <% else %>
      <%= render_waiting(assigns) %>
    <% end %>
    """
  end

  defp render_waiting(assigns) do
    ~H"""
    <style>
      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        font-family: system-ui, -apple-system, sans-serif;
      }

      .waiting-container {
        height: 100vh;
        width: 100vw;
        background: linear-gradient(135deg, #e0f2fe 0%, #ddd6fe 100%);
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 4vh;
      }

      .waiting-message {
        font-size: 6vh;
        font-weight: bold;
        color: #1f2937;
        text-align: center;
        margin-bottom: 2vh;
      }

      .waiting-subtitle {
        font-size: 3vh;
        color: #6b7280;
        text-align: center;
      }
    </style>

    <div class="waiting-container">
      <p class="waiting-message">Hi {@client_name}! 👋</p>
      <p class="waiting-subtitle">Waiting for a task list...</p>
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

    assigns =
      assign(assigns, %{
        task_height: task_height
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
        padding: <%= min(@task_height * 0.15, 1.0) %>rem;
        gap: <%= min(@task_height * 0.15, 1.0) * 2 %>rem;
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
        font-size: <%= @task_height * 0.5 %>vh;
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
