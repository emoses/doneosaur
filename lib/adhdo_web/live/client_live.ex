defmodule AdhdoWeb.ClientLive do
  use AdhdoWeb, :live_view

  alias Adhdo.{Clients, Sessions}

  @impl true
  def mount(%{"name" => client_name}, _session, socket) do
    # Ensure client exists
    {:ok, _client} = Clients.get_or_create_client(client_name)

    # Get active list for this client (will return default list if none assigned)
    list_id = Sessions.get_active_list_for_client(client_name)

    {:ok,
     socket
     |> assign(:client_name, client_name)
     |> assign(:list_id, list_id)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={AdhdoWeb.TaskListComponent} id="task-list" list_id={@list_id} />
    """
  end
end
