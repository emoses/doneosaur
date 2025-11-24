defmodule AdhdoWeb.TaskListLive do
  use AdhdoWeb, :live_view

  @impl true
  def mount(%{"id" => list_id}, _session, socket) do
    list_id = String.to_integer(list_id)

    {:ok, assign(socket, :list_id, list_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={AdhdoWeb.TaskListComponent} id="task-list" list_id={@list_id} />
    """
  end
end
