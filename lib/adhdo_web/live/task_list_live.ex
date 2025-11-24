defmodule AdhdoWeb.TaskListLive do
  use AdhdoWeb, :live_view
  require Logger

  alias AdhdoWeb.{TaskListHelpers, TaskListDisplay}

  @impl true
  def mount(%{"id" => list_id}, _session, socket) do
    list_id = String.to_integer(list_id)

    socket = TaskListHelpers.init_task_list(socket, list_id)

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
      <TaskListDisplay.waiting_screen message="Task list not found" />
    <% end %>
    """
  end
end
