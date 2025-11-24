defmodule Adhdo.ListsTest do
  use Adhdo.DataCase

  alias Adhdo.Lists

  describe "update_task_list_and_tasks/3" do
    test "updates task list, reorders tasks, adds new tasks, and deletes removed tasks" do
      # Create initial task list with 3 tasks
      {:ok, task_list} =
        Lists.create_task_list_with_tasks(%{
          name: "Morning Routine",
          description: "Original description",
          tasks: [
            %{text: "Task 1"},
            %{text: "Task 2"},
            %{text: "Task 3"}
          ]
        })

      # Get the original task IDs to verify they're deleted
      original_task_ids = Enum.map(task_list.tasks, & &1.id)

      # Now update the list:
      # - Change name and description
      # - Delete task2 (middle task)
      # - Reorder: task3 becomes first, task1 becomes second
      # - Add a new task at the end
      # - Edit task1's text
      updated_tasks = [
        # task3 moved to position 1
        %{text: "Task 3", order: 1},
        # task1 moved to position 2 with edited text
        %{text: "Task 1 EDITED", order: 2},
        # task2 is deleted (not in list)
        # New task added at position 3
        %{text: "Task 4 NEW", temp_id: true, order: 3}
      ]

      {:ok, result} =
        Lists.update_task_list_and_tasks(
          task_list,
          %{name: "Morning Routine UPDATED", description: "Updated description"},
          updated_tasks
        )

      # Reload from database to verify changes persisted
      reloaded = Lists.get_task_list!(result.id)

      # Check task list was updated
      assert reloaded.name == "Morning Routine UPDATED"
      assert reloaded.description == "Updated description"

      # Check we have exactly 3 tasks now
      assert length(reloaded.tasks) == 3

      # Sort tasks by order to check them
      sorted_tasks = Enum.sort_by(reloaded.tasks, & &1.order)

      # Check first task (order 1)
      assert Enum.at(sorted_tasks, 0).text == "Task 3"
      assert Enum.at(sorted_tasks, 0).order == 1

      # Check second task (order 2, text edited)
      assert Enum.at(sorted_tasks, 1).text == "Task 1 EDITED"
      assert Enum.at(sorted_tasks, 1).order == 2

      # Check third task (new task, order 3)
      assert Enum.at(sorted_tasks, 2).text == "Task 4 NEW"
      assert Enum.at(sorted_tasks, 2).order == 3

      # Verify all original tasks were deleted (since we delete all and recreate)
      Enum.each(original_task_ids, fn task_id ->
        assert_raise Ecto.NoResultsError, fn ->
          Lists.get_task!(task_id)
        end
      end)
    end
  end
end
