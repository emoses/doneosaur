defmodule Adhdo.Sessions do
  @moduledoc """
  The Sessions context manages active task list sessions and their completion state.

  Each active list gets its own GenServer process that tracks which tasks are completed.
  State is ephemeral and broadcasts changes via PubSub.
  """

  alias Adhdo.Sessions.{ListSession, Supervisor}
  alias Phoenix.PubSub

  @pubsub Adhdo.PubSub

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
end
