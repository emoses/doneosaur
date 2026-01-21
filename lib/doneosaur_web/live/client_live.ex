defmodule DoneosaurWeb.ClientLive do
  use DoneosaurWeb, :live_view

  alias Doneosaur.{Sessions}
  alias DoneosaurWeb.{TaskListHelpers, TaskListDisplay}

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to current list changes
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Doneosaur.PubSub, "current_list")
    end

    list_id = Sessions.get_current_list()

    socket =
      socket
      |> TaskListHelpers.init_task_list(list_id)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_task", params, socket) do
    TaskListHelpers.handle_toggle_task(params, socket)
  end

  @impl true
  def handle_event("reset_list", params, socket) do
    TaskListHelpers.handle_reset_event(params, socket)
  end

  @impl true
  def handle_info({:updated, _}, socket) do
    TaskListHelpers.handle_updated_info(socket)
  end

  @impl true
  def handle_info({:reload}, socket) do
    TaskListHelpers.handle_reload(socket)
  end

  @impl true
  def handle_info({:current_list_changed, new_list_id}, socket) do
    # Unsubscribe from old list updates if we have an active list
    if socket.assigns[:task_list] do
      Sessions.unsubscribe(socket.assigns.task_list.id)
    end

    # Switch to the new list
    socket = TaskListHelpers.init_task_list(socket, new_list_id)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @task_list do %>
      <TaskListDisplay.task_list task_list={@task_list} completed_tasks={@completed_tasks} />
    <% else %>
      <TaskListDisplay.waiting_screen
        message="Hi! 👋"
        subtitle="Waiting for a task list..."
      />
    <% end %>
    """
  end
end
