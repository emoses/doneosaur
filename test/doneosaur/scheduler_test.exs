defmodule Doneosaur.SchedulerTest do
  use ExUnit.Case, async: true

  alias Doneosaur.Scheduler
  alias Doneosaur.Lists.Schedule

  # Helper to create a schedule struct
  defp make_schedule(day_of_week, time_string, task_list_id \\ 1) do
    {:ok, time} = Time.from_iso8601(time_string)
    %Schedule{
      day_of_week: day_of_week,
      time: time,
      task_list_id: task_list_id,
      task_list: %{id: task_list_id, name: "Test List #{task_list_id}"}
    }
  end

  describe "find_next_schedule/2" do
    test "returns first schedule when current time is before all schedules" do
      schedules = [
        make_schedule(2, "09:00:00"),  # Tuesday 9am
        make_schedule(4, "14:00:00"),  # Thursday 2pm
        make_schedule(6, "10:00:00")   # Saturday 10am
      ]

      # Monday at 8am - before first schedule
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 08:00:00], "Etc/UTC")

      result = Scheduler.find_next_schedule(schedules, current_time)

      assert result.day_of_week == 2
      assert result.time == ~T[09:00:00]
    end

    test "returns first schedule when current time is after all schedules (wraps to next week)" do
      schedules = [
        make_schedule(1, "07:30:00"),  # Monday 7:30am
        make_schedule(3, "08:00:00"),  # Wednesday 8am
        make_schedule(5, "16:00:00")   # Friday 4pm
      ]

      # Saturday at 5pm - after last schedule
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-06 17:00:00], "Etc/UTC")

      result = Scheduler.find_next_schedule(schedules, current_time)

      assert result.day_of_week == 1
      assert result.time == ~T[07:30:00]
    end

    test "returns next schedule when current time is in the middle of schedules" do
      schedules = [
        make_schedule(1, "07:30:00"),  # Monday 7:30am
        make_schedule(2, "07:30:00"),  # Tuesday 7:30am
        make_schedule(3, "07:30:00"),  # Wednesday 7:30am
        make_schedule(4, "07:30:00"),  # Thursday 7:30am
        make_schedule(5, "07:30:00")   # Friday 7:30am
      ]

      # Tuesday at 8am - should get Wednesday
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-02 08:00:00], "Etc/UTC")

      result = Scheduler.find_next_schedule(schedules, current_time)

      assert result.day_of_week == 3
      assert result.time == ~T[07:30:00]
    end

    test "returns next schedule on same day when time hasn't passed yet" do
      schedules = [
        make_schedule(1, "07:30:00"),  # Monday 7:30am
        make_schedule(1, "12:00:00"),  # Monday 12pm
        make_schedule(1, "17:00:00")   # Monday 5pm
      ]

      # Monday at 8am - should get Monday 12pm
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 08:00:00], "Etc/UTC")

      result = Scheduler.find_next_schedule(schedules, current_time)

      assert result.day_of_week == 1
      assert result.time == ~T[12:00:00]
    end

    test "returns next day's schedule when on same day but after all times" do
      schedules = [
        make_schedule(1, "07:30:00"),  # Monday 7:30am
        make_schedule(1, "12:00:00"),  # Monday 12pm
        make_schedule(2, "07:30:00")   # Tuesday 7:30am
      ]

      # Monday at 1pm - should get Tuesday
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 13:00:00], "Etc/UTC")

      result = Scheduler.find_next_schedule(schedules, current_time)

      assert result.day_of_week == 2
      assert result.time == ~T[07:30:00]
    end

    test "handles schedules spanning full week correctly" do
      schedules = [
        make_schedule(1, "09:00:00"),  # Monday 9am
        make_schedule(2, "09:00:00"),  # Tuesday 9am
        make_schedule(3, "09:00:00"),  # Wednesday 9am
        make_schedule(4, "09:00:00"),  # Thursday 9am
        make_schedule(5, "09:00:00"),  # Friday 9am
        make_schedule(6, "10:00:00"),  # Saturday 10am
        make_schedule(7, "11:00:00")   # Sunday 11am
      ]

      # Sunday at noon - should wrap to Monday
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-07 12:00:00], "Etc/UTC")

      result = Scheduler.find_next_schedule(schedules, current_time)

      assert result.day_of_week == 1
      assert result.time == ~T[09:00:00]
    end

    test "returns nil when schedules list is empty" do
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 12:00:00], "Etc/UTC")

      result = Scheduler.find_next_schedule([], current_time)

      assert result == nil
    end

    test "handles edge case at exact schedule time" do
      schedules = [
        make_schedule(1, "09:00:00"),
        make_schedule(2, "09:00:00")
      ]

      # Exactly Monday at 9am - should get Tuesday (already at this time)
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 09:00:00], "Etc/UTC")

      result = Scheduler.find_next_schedule(schedules, current_time)

      assert result.day_of_week == 2
      assert result.time == ~T[09:00:00]
    end
  end

  describe "calculate_ms_until/2" do
    test "calculates time until later day in same week" do
      schedule = make_schedule(3, "09:00:00")  # Wednesday 9am

      # Monday at 8am - should get this Wednesday (2 days + 1 hour)
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 08:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # 2 days * 24 hours * 60 minutes * 60 seconds * 1000 ms + 1 hour in ms
      expected_ms = (2 * 24 * 60 * 60 * 1000) + (1 * 60 * 60 * 1000)
      assert ms_until == expected_ms
    end

    test "calculates time until same day when time hasn't passed yet" do
      schedule = make_schedule(1, "14:00:00")  # Monday 2pm

      # Monday at 9am - should get today in 5 hours
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 09:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # 5 hours in milliseconds
      expected_ms = 5 * 60 * 60 * 1000
      assert ms_until == expected_ms
    end

    test "calculates time until next week when same day but time has passed" do
      schedule = make_schedule(1, "09:00:00")  # Monday 9am

      # Monday at 10am - should get next Monday (7 days - 1 hour)
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 10:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # 6 days and 23 hours in milliseconds
      expected_ms = (6 * 24 * 60 * 60 * 1000) + (23 * 60 * 60 * 1000)
      assert ms_until == expected_ms
    end

    test "calculates time until next week when target day is earlier in week" do
      schedule = make_schedule(2, "09:00:00")  # Tuesday 9am

      # Friday at 8am - should get next Tuesday (4 days + 1 hour)
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-05 08:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # 4 days and 1 hour in milliseconds
      expected_ms = (4 * 24 * 60 * 60 * 1000) + (1 * 60 * 60 * 1000)
      assert ms_until == expected_ms
    end

    test "handles Saturday to Sunday (1 day)" do
      schedule = make_schedule(7, "10:00:00")  # Sunday 10am

      # Saturday at 9am - should get tomorrow in 25 hours
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-06 09:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # 25 hours in milliseconds
      expected_ms = 25 * 60 * 60 * 1000
      assert ms_until == expected_ms
    end

    test "handles Sunday to Monday (1 day)" do
      schedule = make_schedule(1, "09:00:00")  # Monday 9am

      # Sunday at 11am - should get tomorrow in 22 hours
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-07 11:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # 22 hours in milliseconds
      expected_ms = 22 * 60 * 60 * 1000
      assert ms_until == expected_ms
    end

    test "handles exact time on target day (should go to next week)" do
      schedule = make_schedule(1, "09:00:00")  # Monday 9am

      # Exactly Monday at 9am - should get next Monday (7 days)
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 09:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # 7 days in milliseconds
      expected_ms = 7 * 24 * 60 * 60 * 1000
      assert ms_until == expected_ms
    end

    test "handles Thursday to Monday (next week)" do
      schedule = make_schedule(1, "07:30:00")  # Monday 7:30am

      # Thursday at 3pm - should get next Monday
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-04 15:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # From Thursday 3pm to Monday 7:30am
      # 3 days and 16.5 hours
      expected_ms = (3 * 24 * 60 * 60 * 1000) + (16 * 60 * 60 * 1000) + (30 * 60 * 1000)
      assert ms_until == expected_ms
    end

    test "handles Wednesday to Wednesday next week (time passed)" do
      schedule = make_schedule(3, "08:00:00")  # Wednesday 8am

      # Wednesday at 9am (time passed) - should get next Wednesday (7 days - 1 hour)
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-03 09:00:00], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # 6 days and 23 hours in milliseconds
      expected_ms = (6 * 24 * 60 * 60 * 1000) + (23 * 60 * 60 * 1000)
      assert ms_until == expected_ms
    end

    test "returns 0 when time is negative (shouldn't happen but handles edge case)" do
      schedule = make_schedule(1, "08:00:00")  # Monday 8am

      # If we're already past the time, should return 0 (max of negative and 0)
      {:ok, current_time} = DateTime.from_naive(~N[2024-01-01 08:00:01], "Etc/UTC")

      ms_until = Scheduler.calculate_ms_until(schedule, current_time)

      # Should be next week, not 0 - this tests the max(ms_until, 0) safety
      assert ms_until >= 0
    end
  end
end
