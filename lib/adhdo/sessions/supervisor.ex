defmodule Adhdo.Sessions.Supervisor do
  @moduledoc """
  DynamicSupervisor for managing active task list sessions.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a new list session under the supervisor.
  """
  def start_session(list_id) do
    child_spec = {Adhdo.Sessions.ListSession, list_id}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Stops an active list session.
  """
  def stop_session(list_id) do
    case Registry.lookup(Adhdo.Sessions.Registry, list_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> :ok
    end
  end
end
