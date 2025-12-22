defmodule Doneosaur.Scheduler do
  @moduledoc """
  GenServer that manages scheduled task list activations.

  Loads all schedules from the database, calculates when the next activation should occur,
  and triggers task list activation at the scheduled time.

  When schedules change in the database, call `reload/0` to pick up the changes.
  """
  use GenServer
  require Logger

  alias Doneosaur.{Lists, Sessions}

  ## Client API

  @doc """
  Starts the scheduler GenServer.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Reloads schedules from the database and reschedules the next activation.
  Call this whenever schedules are created, updated, or deleted.
  """
  def reload do
    GenServer.call(__MODULE__, :reload)
  end

  ## Server Callbacks

  @impl true
  def init(:ok) do
    Logger.info("Starting Doneosaur.Scheduler")

    state = %{
      schedules: [],
      timer_ref: nil
    }

    # Load schedules and set up first activation
    {:ok, state, {:continue, :load_schedules}}
  end

  @impl true
  def handle_continue(:load_schedules, state) do
    {:noreply, load_and_schedule(state)}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    Logger.info("Reloading schedules")
    new_state = load_and_schedule(state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({:activate, task_list_id}, state) do
    Logger.info("Scheduled activation of task list #{task_list_id}")
    Sessions.set_current_list(task_list_id)

    # Schedule the next activation
    new_state = schedule_next(state)
    {:noreply, new_state}
  end

  ## Private Functions

  defp load_and_schedule(state) do
    # Cancel existing timer if any
    if state.timer_ref do
      Process.cancel_timer(state.timer_ref)
    end

    # Load all schedules (sorted by day and time)
    schedules = Lists.list_schedules()

    Logger.info("Loaded #{length(schedules)} schedules")

    # Schedule the next activation
    state
    |> Map.put(:schedules, schedules)
    |> schedule_next()
  end

  defp schedule_next(state) do
    now = DateTime.now!(get_timezone())

    case find_next_schedule(state.schedules, now) do
      nil ->
        Logger.info("No schedules found, nothing to schedule")
        Map.put(state, :timer_ref, nil)

      next_schedule ->
        # Calculate when this schedule should activate
        ms_until_activation = calculate_ms_until(next_schedule, now)
        Logger.info("Next activation: #{format_schedule(next_schedule)} in #{ms_until_activation}ms")

        # Schedule timer for next activation
        timer_ref = Process.send_after(self(), {:activate, next_schedule.task_list_id}, ms_until_activation)
        Map.put(state, :timer_ref, timer_ref)
    end
  end

  @doc """
  Calculates milliseconds until a schedule should activate.
  Returns the number of milliseconds from now until the next occurrence of this schedule.
  """
  def calculate_ms_until(schedule, now) do
    current_day = Date.day_of_week(now)
    target_day = schedule.day_of_week

    diff = target_day - current_day
    diff = if diff < 0 or (diff == 0 && Time.compare(schedule.time, DateTime.to_time(now)) != :gt), do: diff + 7, else: diff
    {:ok, target_datetime} = DateTime.new(Date.add(now, diff), schedule.time, get_timezone())

    ms_until = DateTime.diff(target_datetime, now, :millisecond)
  t max(ms_until, 0)
  end

  defp is_before?(t, schedule) do
    current_day = Date.day_of_week(t)
    current_time = DateTime.to_time(t)

    current_day < schedule.day_of_week or (current_day == schedule.day_of_week and Time.compare(current_time, schedule.time) == :lt)
  end

  defp is_after?(t, schedule) do
    current_day = Date.day_of_week(t)
    current_time = DateTime.to_time(t)

    current_day > schedule.day_of_week or (current_day == schedule.day_of_week and Time.compare(current_time, schedule.time) == :gt)
  end

  @doc """
  Finds the next schedule to activate given a list of schedules and current time.
  Returns the schedule struct, or nil if no schedules exist.

  Schedules should be sorted by day_of_week and time.
  """
  def find_next_schedule(schedules, current_time)
  def find_next_schedule([], _current_time), do: nil

  def find_next_schedule(schedules, current_time) do
    [first | _] = schedules
    last = List.last(schedules)

    cond do
      # If it's before the first schedule or after the last schedule, use the first schedule
      is_before?(current_time, first) -> first
      is_after?(current_time, last) -> first
      true ->
        # Find the first schedule that comes after current time
        # If none found (e.g., current_time equals last schedule), wrap to first
        Enum.find(schedules, first, fn schedule -> is_before?(current_time, schedule) end)
    end
  end

  defp format_schedule(schedule) do
    day_name = Doneosaur.Lists.Schedule.day_name(schedule.day_of_week)
    time_str = Time.to_string(schedule.time)

    "#{day_name} at #{time_str} -> #{schedule.task_list_id}"
  end

  defp get_timezone do
    Application.get_env(:doneosaur, :timezone, "Etc/UTC")
  end
end
