defmodule Doneosaur.SessionsTest do
  use Doneosaur.DataCase

  alias Doneosaur.{Sessions, Lists, Scheduler}

  describe "determine_default_list/0 with schedules" do
    test "returns most recently scheduled list on Monday afternoon" do
      # Create task lists
      {:ok, morning_list} = Lists.create_task_list(%{name: "Morning Routine"})
      {:ok, bedtime_list} = Lists.create_task_list(%{name: "Bedtime Routine"})

      # Create schedules
      # Monday 7:30am - Morning Routine
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: morning_list.id,
          day_of_week: 1,
          time: ~T[07:30:00]
        })

      # Friday 8pm - Bedtime
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: bedtime_list.id,
          day_of_week: 5,
          time: ~T[20:00:00]
        })

      # Reload scheduler to pick up new schedules
      Scheduler.reload()

      # Test as if it's Monday at 2pm (after morning schedule, before Friday)
      # Monday = day 1 in ISO week date (2024-01-01 is a Monday)
      {:ok, monday_2pm} = DateTime.from_naive(~N[2024-01-01 14:00:00], "Etc/UTC")

      # Should return the morning list (most recent that has passed)
      assert Scheduler.get_most_recent_list_id(monday_2pm) == morning_list.id
    end

    test "returns most recently scheduled list on Saturday" do
      # Create task lists
      {:ok, morning_list} = Lists.create_task_list(%{name: "Morning Routine"})
      {:ok, homework_list} = Lists.create_task_list(%{name: "Homework"})
      {:ok, bedtime_list} = Lists.create_task_list(%{name: "Bedtime Routine"})

      # Monday 7:30am - Morning Routine
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: morning_list.id,
          day_of_week: 1,
          time: ~T[07:30:00]
        })

      # Wednesday 3:30pm - Homework
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: homework_list.id,
          day_of_week: 3,
          time: ~T[15:30:00]
        })

      # Friday 8pm - Bedtime
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: bedtime_list.id,
          day_of_week: 5,
          time: ~T[20:00:00]
        })

      Scheduler.reload()

      # Saturday at 10am (2024-01-06 is a Saturday)
      {:ok, saturday_10am} = DateTime.from_naive(~N[2024-01-06 10:00:00], "Etc/UTC")

      # Should return Friday bedtime (most recent)
      assert Scheduler.get_most_recent_list_id(saturday_10am) == bedtime_list.id
    end

    test "wraps to previous week when before first schedule" do
      # Create task lists
      {:ok, morning_list} = Lists.create_task_list(%{name: "Morning Routine"})
      {:ok, bedtime_list} = Lists.create_task_list(%{name: "Bedtime Routine"})

      # Wednesday 8am
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: morning_list.id,
          day_of_week: 3,
          time: ~T[08:00:00]
        })

      # Friday 8pm
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: bedtime_list.id,
          day_of_week: 5,
          time: ~T[20:00:00]
        })

      Scheduler.reload()

      # Monday at 6am (before Wednesday schedule)
      {:ok, monday_6am} = DateTime.from_naive(~N[2024-01-01 06:00:00], "Etc/UTC")

      # Should wrap to previous week's Friday bedtime
      assert Scheduler.get_most_recent_list_id(monday_6am) == bedtime_list.id
    end

    test "handles multiple schedules on same day" do
      # Create task lists
      {:ok, morning_list} = Lists.create_task_list(%{name: "Morning Routine"})
      {:ok, lunch_list} = Lists.create_task_list(%{name: "Lunch"})
      {:ok, bedtime_list} = Lists.create_task_list(%{name: "Bedtime"})

      # Monday 7am
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: morning_list.id,
          day_of_week: 1,
          time: ~T[07:00:00]
        })

      # Monday 12pm
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: lunch_list.id,
          day_of_week: 1,
          time: ~T[12:00:00]
        })

      # Monday 8pm
      {:ok, _} =
        Lists.create_schedule(%{
          task_list_id: bedtime_list.id,
          day_of_week: 1,
          time: ~T[20:00:00]
        })

      Scheduler.reload()

      # Monday at 2pm (after lunch, before bedtime)
      {:ok, monday_2pm} = DateTime.from_naive(~N[2024-01-01 14:00:00], "Etc/UTC")

      # Should return lunch (most recent)
      assert Scheduler.get_most_recent_list_id(monday_2pm) == lunch_list.id
    end
  end

  describe "determine_default_list/0 fallback behavior" do
    test "falls back to 'Morning Routine' when no schedules exist" do
      # Create lists without schedules
      {:ok, _other_list} = Lists.create_task_list(%{name: "Bedtime Routine"})
      {:ok, morning_list} = Lists.create_task_list(%{name: "Morning Routine"})

      Scheduler.reload()

      # Should fall back to Morning Routine
      assert Sessions.determine_default_list() == morning_list.id
    end

    test "falls back to first list when no schedules and no 'Morning Routine'" do
      # Create lists without "Morning Routine"
      {:ok, first_list} = Lists.create_task_list(%{name: "Bedtime Routine"})
      {:ok, _second_list} = Lists.create_task_list(%{name: "After School"})

      Scheduler.reload()

      # Should return first list
      assert Sessions.determine_default_list() == first_list.id
    end

    test "returns nil when no lists exist" do
      Scheduler.reload()

      assert Sessions.determine_default_list() == nil
    end
  end
end
