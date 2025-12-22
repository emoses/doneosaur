defmodule Doneosaur.Sessions do
  @moduledoc """
  The Sessions context manages active task list sessions and their completion state.

  Each active list gets its own GenServer process that tracks which tasks are completed.
  State is ephemeral and broadcasts changes via PubSub.

  Also tracks which clients are currently viewing which lists (ephemeral, in-memory).
  """

  alias Doneosaur.Sessions.{ListSession, Supervisor}
  alias Phoenix.PubSub
  alias Doneosaur.Lists

  @pubsub Doneosaur.PubSub
  @client_registry_name __MODULE__.ClientRegistry
  @default_list_name "Morning Routine"

  def start_link(_opts) do
    default_list_id = determine_default_list()

    Agent.start_link(
      fn -> %{current_list: default_list_id, clients: %{}} end,
      name: @client_registry_name
    )
  end

  @doc """
  Determines which list should be the default at startup.
  Returns the ID of the "Morning Routine" list if it exists,
  otherwise returns the first available list, or nil if no lists exist.
  """
  def determine_default_list do
    case Lists.get_task_list_by_name(@default_list_name) do
      nil ->
        case Lists.list_task_lists() do
          [] -> nil
          [first_list | _] -> first_list.id
        end

      task_list ->
        task_list.id
    end
  end

  @doc """
  Starts a new session for a task list.
  If a session already exists, returns the existing session.
  """
  def start_session(list_id) do
    case session_exists?(list_id) do
      true -> {:ok, :already_started}
      false -> Supervisor.start_session(list_id)
    end
  end

  @doc """
  Stops a session for a task list.
  """
  def stop_session(list_id) do
    Supervisor.stop_session(list_id)
  end

  @doc """
  Checks if a session exists for a task list.
  """
  def session_exists?(list_id) do
    case Registry.lookup(Doneosaur.Sessions.Registry, list_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  @doc """
  Gets the set of completed task IDs for a list session.
  """
  def get_completed_tasks(list_id) do
    ListSession.get_completed_tasks(list_id)
  end

  @doc """
  Toggles a task's completion state and broadcasts the change.
  """
  def toggle_task(list_id, task_id) do
    ListSession.toggle_task(list_id, task_id)
  end

  @doc """
  Checks if a task is completed.
  """
  def task_completed?(list_id, task_id) do
    ListSession.task_completed?(list_id, task_id)
  end

  @doc """
  Resets a task list session, clearing all completed tasks.
  """
  def reset_session(list_id) do
    if session_exists?(list_id) do
      ListSession.reset(list_id)
    end
  end

  @doc """
  Resets a task list and asks clients to reload its data
  """
  def reload_list(list_id) do
    if session_exists?(list_id) do
      ListSession.reload(list_id)
    end
  end

  @doc """
  Returns the PubSub topic for a task list.
  """
  def topic(list_id), do: ListSession.topic(list_id)

  @doc """
  Subscribes the current process to updates for a task list.
  """
  def subscribe(list_id) do
    PubSub.subscribe(@pubsub, topic(list_id))
  end

  @doc """
  Unsubscribes the current process from updates for a task list.
  """
  def unsubscribe(list_id) do
    PubSub.unsubscribe(@pubsub, topic(list_id))
  end

  ## Client Registry functions

  @doc """
  Gets the current list ID.
  """
  def get_current_list do
    Agent.get(@client_registry_name, fn state -> state.current_list end)
  end

  @doc """
  Sets the current list ID and broadcasts to all clients.
  """
  def set_current_list(list_id) do
    Agent.update(@client_registry_name, fn state ->
      %{state | current_list: list_id}
    end)

    # Broadcast to all clients that the current list changed
    PubSub.broadcast(@pubsub, "current_list", {:current_list_changed, list_id})

    # Reset the target list if it has a session
    if session_exists?(list_id) do
      ListSession.reset(list_id)
    end

    :ok
  end
end
