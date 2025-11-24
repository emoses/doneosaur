defmodule Adhdo.Sessions do
  @moduledoc """
  The Sessions context manages active task list sessions and their completion state.

  Each active list gets its own GenServer process that tracks which tasks are completed.
  State is ephemeral and broadcasts changes via PubSub.

  Also tracks which clients are currently viewing which lists (ephemeral, in-memory).
  """

  alias Adhdo.Sessions.{ListSession, Supervisor}
  alias Phoenix.PubSub

  @pubsub Adhdo.PubSub
  @client_registry_name __MODULE__.ClientRegistry

  def start_link(_opts) do
    Agent.start_link(
      fn -> %{default_list: 7, clients: %{}} end,
      name: @client_registry_name
    )
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
    case Registry.lookup(Adhdo.Sessions.Registry, list_id) do
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
    ListSession.reset(list_id)
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
  Activates a list for specific clients.
  This sets which list each client should display.
  """
  def activate_list_for_clients(list_id, client_names) when is_list(client_names) do
    # Ensure the list session exists
    start_session(list_id)

    # Update client registry
    Agent.update(@client_registry_name, fn state ->
      updated_clients =
        Enum.reduce(client_names, state.clients, fn client_name, acc ->
          Map.put(acc, client_name, list_id)
        end)

      %{state | clients: updated_clients}
    end)

    :ok
  end

  @doc """
  Gets the active list ID for a client.
  Returns the default list if no list is active for this client.
  """
  def get_active_list_for_client(client_name) do
    Agent.get(@client_registry_name, fn state ->
      Map.get(state.clients, client_name, state.default_list)
    end)
  end

  @doc """
  Deactivates the list for a client.
  After deactivation, the client will use the default list.
  """
  def deactivate_client(client_name) do
    Agent.update(@client_registry_name, fn state ->
      %{state | clients: Map.delete(state.clients, client_name)}
    end)
  end

  @doc """
  Gets all clients viewing a specific list.
  """
  def get_clients_for_list(list_id) do
    Agent.get(@client_registry_name, fn state ->
      state.clients
      |> Enum.filter(fn {_client, lid} -> lid == list_id end)
      |> Enum.map(fn {client, _} -> client end)
    end)
  end

  @doc """
  Gets the default list ID.
  This is the list that clients see when they don't have an active list assigned.
  """
  def get_default_list do
    Agent.get(@client_registry_name, fn state -> state.default_list end)
  end

  @doc """
  Sets the default list ID.
  This will be used for any clients that don't have a specific list assigned.
  """
  def set_default_list(list_id) do
    Agent.update(@client_registry_name, fn state ->
      %{state | default_list: list_id}
    end)
  end
end
