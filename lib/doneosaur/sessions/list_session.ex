defmodule Doneosaur.Sessions.ListSession do
  @moduledoc """
  A GenServer that manages the state for a single active task list session.

  Each session tracks which tasks are completed and broadcasts changes via PubSub.
  """

  use GenServer
  alias Phoenix.PubSub

  @pubsub Doneosaur.PubSub

  defstruct [:list_id, :completed_tasks]

  ## Client API

  @doc """
  Starts a new list session.
  """
  def start_link(list_id) do
    GenServer.start_link(__MODULE__, list_id, name: via_tuple(list_id))
  end

  @doc """
  Gets the set of completed task IDs for this session.
  """
  def get_completed_tasks(list_id) do
    GenServer.call(via_tuple(list_id), :get_completed_tasks)
  end

  @doc """
  Toggles a task's completion state.
  """
  def toggle_task(list_id, task_id) do
    GenServer.call(via_tuple(list_id), {:toggle_task, task_id})
  end

  @doc """
  Checks if a task is completed.
  """
  def task_completed?(list_id, task_id) do
    GenServer.call(via_tuple(list_id), {:task_completed?, task_id})
  end

  @doc """
  Resets the session, clearing all completed tasks.
  """
  def reset(list_id) do
    GenServer.call(via_tuple(list_id), :reset)
  end

  @doc """
  Resets the session and asks all clients to reload their tasks
  """
  def reload(list_id) do
    GenServer.call(via_tuple(list_id), :reload)
  end

  @doc """
  Returns the PubSub topic for this list.
  """
  def topic(list_id), do: "task_list:#{list_id}"

  ## Server Callbacks

  @impl true
  def init(list_id) do
    {:ok, %__MODULE__{list_id: list_id, completed_tasks: MapSet.new()}}
  end

  @impl true
  def handle_call(:get_completed_tasks, _from, state) do
    {:reply, state.completed_tasks, state}
  end

  @impl true
  def handle_call({:toggle_task, task_id}, _from, state) do
    {new_completed, completed?} =
      if MapSet.member?(state.completed_tasks, task_id) do
        {MapSet.delete(state.completed_tasks, task_id), false}
      else
        {MapSet.put(state.completed_tasks, task_id), true}
      end

    new_state = %{state | completed_tasks: new_completed}

    PubSub.broadcast(@pubsub, topic(state.list_id), {:updated, {:toggled, task_id, completed?}})

    {:reply, {:ok, completed?}, new_state}
  end

  @impl true
  def handle_call({:task_completed?, task_id}, _from, state) do
    completed = MapSet.member?(state.completed_tasks, task_id)
    {:reply, completed, state}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    new_state = %{state | completed_tasks: MapSet.new()}
    PubSub.broadcast(@pubsub, topic(state.list_id), {:updated, {:session_reset}})
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    new_state = %{state | completed_tasks: MapSet.new()}
    PubSub.broadcast(@pubsub, topic(state.list_id), {:reload})
    {:reply, :ok, new_state}
  end

  ## Helpers

  defp via_tuple(list_id) do
    {:via, Registry, {Doneosaur.Sessions.Registry, list_id}}
  end
end
