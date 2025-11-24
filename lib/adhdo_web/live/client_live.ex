defmodule AdhdoWeb.ClientLive do
  use AdhdoWeb, :live_view

  alias Adhdo.{Clients, Sessions}
  alias AdhdoWeb.{TaskListHelpers, TaskListDisplay}

  @impl true
  def mount(%{"name" => client_name}, _session, socket) do
    # Ensure client exists
    {:ok, _client} = Clients.get_or_create_client(client_name)

    # Get active list for this client (will return default list if none assigned)
    list_id = Sessions.get_current_list()

    socket =
      socket
      |> assign(:client_name, client_name)
      |> TaskListHelpers.init_task_list(list_id)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_task", params, socket) do
    TaskListHelpers.handle_toggle_task(params, socket)
  end

  @impl true
  def handle_event("reset_list", params, socket) do
    TaskListHelpers.handle_reset(params, socket)
  end

  @impl true
  def handle_info({:updated, _}, socket) do
    TaskListHelpers.handle_updated_info(socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @task_list do %>
      <TaskListDisplay.task_list task_list={@task_list} completed_tasks={@completed_tasks} />
    <% else %>
      <TaskListDisplay.waiting_screen
        message={"Hi #{@client_name}! 👋"}
        subtitle="Waiting for a task list..."
      />
    <% end %>
    """
  end
end
