defmodule Adhdo.SessionsTest do
  use Adhdo.DataCase

  alias Adhdo.{Sessions, Lists}

  describe "determine_default_list/0" do
    test "returns 'Morning Routine' list ID when it exists" do
      # Create some lists, including "Morning Routine"
      {:ok, _other_list} = Lists.create_task_list(%{name: "Bedtime Routine"})
      {:ok, morning_list} = Lists.create_task_list(%{name: "Morning Routine"})

      # The function should return the Morning Routine list ID
      assert Sessions.determine_default_list() == morning_list.id
    end

    test "returns first available list ID when 'Morning Routine' doesn't exist" do
      # Create some lists without "Morning Routine"
      {:ok, _first_list} = Lists.create_task_list(%{name: "Bedtime Routine"})
      {:ok, _second_list} = Lists.create_task_list(%{name: "After School"})

      # Should return one of the available list IDs
      default_list_id = Sessions.determine_default_list()
      all_lists = Lists.list_task_lists()

      assert default_list_id in Enum.map(all_lists, & &1.id)
      assert default_list_id != nil
    end

    test "returns nil when no lists exist" do
      # No lists in the database

      # When no lists exist, should return nil
      assert Sessions.determine_default_list() == nil
    end
  end
end
