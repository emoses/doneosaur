defmodule DoneosaurWeb.TaskListHelpers do
  @moduledoc """
  Shared helpers for LiveViews that display task lists.
  Handles session management, PubSub subscriptions, and event handling.
  """

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [connected?: 1]

  alias Doneosaur.{Lists, Sessions}

  def init_task_list(socket, nil) do
    socket
    |> assign(:task_list, nil)
    |> assign(:completed_tasks, [])
  end

  @doc """
  Initializes a task list session in a LiveView socket.
  Call this from mount/3 after determining which list_id to display.
  """
  def init_task_list(socket, list_id) do
    case Lists.get_task_list!(list_id) do
      nil ->
        socket
        |> assign(:task_list, nil)
        |> assign(:completed_tasks, MapSet.new())

      task_list ->
        # Start a session for this list if it doesn't exist
        Sessions.start_session(list_id)

        # Subscribe to updates if connected
        if connected?(socket) do
          Sessions.subscribe(list_id)
        end

        # Get current completion state
        completed_tasks = Sessions.get_completed_tasks(list_id)

        socket
        |> assign(:task_list, task_list)
        |> assign(:completed_tasks, completed_tasks)
    end
  end

  @doc """
  Handles the toggle_task event.
  Call this from handle_event/3 in your LiveView.
  """
  def handle_toggle_task(%{"task-id" => task_id}, socket) do
    list_id = socket.assigns.task_list.id

    {:ok, _completed?} = Sessions.toggle_task(list_id, task_id)

    {:noreply, socket}
  end

  def handle_reset_event(_, socket) do
    list_id = socket.assigns.task_list.id

    :ok = Sessions.reset_session(list_id)

    {:noreply, socket}
  end

  def handle_reload(socket) do
    socket =
      case Lists.get_task_list!(socket.assigns.task_list.id) do
        nil ->
          socket
          |> assign(:task_list, nil)

        task_list ->
          socket
          |> assign(:task_list, task_list)
      end

    {:noreply, socket}
  end

  @doc """
  Handles PubSub :updated message.
  Call this from handle_info/2 in your LiveView.
  """
  def handle_updated_info(socket) do
    completed_tasks = Sessions.get_completed_tasks(socket.assigns.task_list.id)

    {:noreply, assign(socket, :completed_tasks, completed_tasks)}
  end
end
