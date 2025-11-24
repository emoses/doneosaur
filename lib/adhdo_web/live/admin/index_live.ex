defmodule AdhdoWeb.Admin.IndexLive do
  use AdhdoWeb, :live_view

  alias Adhdo.{Lists, Sessions}

  @impl true
  def mount(_params, _session, socket) do
    task_lists = Lists.list_task_lists()
    current_list_id = Sessions.get_current_list()

    {:ok,
     socket
     |> assign(:task_lists, task_lists)
     |> assign(:current_list_id, current_list_id)}
  end

  @impl true
  def handle_event("set_current_list", %{"list-id" => list_id}, socket) do
    list_id = String.to_integer(list_id)
    :ok = Sessions.set_current_list(list_id)

    {:noreply,
     socket
     |> assign(:current_list_id, list_id)
     |> put_flash(:info, "Current list updated successfully")}
  end

  @impl true
  def handle_event("delete_list", %{"list-id" => list_id}, socket) do
    list_id = String.to_integer(list_id)
    task_list = Lists.get_task_list!(list_id)

    case Lists.delete_task_list(task_list) do
      {:ok, _} ->
        task_lists = Lists.list_task_lists()

        # If we deleted the current list, clear it
        current_list_id =
          if socket.assigns.current_list_id == list_id do
            Sessions.set_current_list(nil)
            nil
          else
            socket.assigns.current_list_id
          end

        {:noreply,
         socket
         |> assign(:task_lists, task_lists)
         |> assign(:current_list_id, current_list_id)
         |> put_flash(:info, "Task list deleted successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete task list")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="admin-container">
      <div class="admin-header">
        <h1>Task Lists</h1>
        <.link navigate={~p"/admin/lists/new"} class="btn btn-primary">
          New Task List
        </.link>
      </div>

      <%= if @task_lists == [] do %>
        <div class="empty-state">
          <p>No task lists yet</p>
          <.link navigate={~p"/admin/lists/new"} class="btn btn-primary">
            Create your first task list
          </.link>
        </div>
      <% else %>
        <div>
          <div :for={list <- @task_lists} class="card">
            <div class="card-header">
              <div style="flex: 1">
                <h2 class="card-title">
                  {list.name}
                  <%= if list.id == @current_list_id do %>
                    <span class="badge badge-success">Current List</span>
                  <% end %>
                </h2>
                <p :if={list.description} class="card-description">{list.description}</p>
                <p class="text-muted">
                  {length(list.tasks)} {if length(list.tasks) == 1, do: "task", else: "tasks"}
                </p>
              </div>

              <div class="card-actions">
                <%= if list.id != @current_list_id do %>
                  <button
                    phx-click="set_current_list"
                    phx-value-list-id={list.id}
                    class="btn btn-secondary"
                  >
                    Set as Current
                  </button>
                <% end %>
                <.link navigate={~p"/admin/lists/#{list.id}/edit"} class="btn btn-secondary">
                  Edit
                </.link>
                <button
                  phx-click="delete_list"
                  phx-value-list-id={list.id}
                  data-confirm="Are you sure you want to delete this task list?"
                  class="btn btn-danger"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
