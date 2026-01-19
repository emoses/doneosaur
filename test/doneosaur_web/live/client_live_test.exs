defmodule DoneosaurWeb.ClientLiveTest do
  use DoneosaurWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Doneosaur.{Lists, Sessions}

  describe "ClientLive" do
    test "renders waiting screen when no current list is set", %{conn: conn} do
      # Ensure there's no current list
      Sessions.set_current_list(nil)

      {:ok, _view, html} = live(conn, "/")

      # Should show waiting screen
      assert html =~ "Hi!"
      assert html =~ "Waiting for a task list..."

      # Should not show task list
      refute html =~ "task-item"
    end

    test "renders task list when current list is set", %{conn: conn} do
      # Create a task list
      {:ok, task_list} =
        Lists.create_task_list_with_tasks(%{
          name: "Morning Routine",
          description: "Tasks for morning",
          tasks: [
            %{text: "Brush teeth"},
            %{text: "Get dressed"}
          ]
        })

      # Set it as current list
      Sessions.set_current_list(task_list.id)

      {:ok, _view, html} = live(conn, "/")

      # Should show task list
      assert html =~ "Morning Routine"
      assert html =~ "Brush teeth"
      assert html =~ "Get dressed"

      # Should not show waiting screen
      refute html =~ "Waiting for a task list..."
    end

    test "switches to new list when current list changes", %{conn: conn} do
      # Create two task lists
      {:ok, task_list1} =
        Lists.create_task_list_with_tasks(%{
          name: "Morning Routine",
          tasks: [%{text: "Brush teeth"}]
        })

      {:ok, task_list2} =
        Lists.create_task_list_with_tasks(%{
          name: "Bedtime Routine",
          tasks: [%{text: "Put on pajamas"}]
        })

      # Set first list as current
      Sessions.set_current_list(task_list1.id)

      {:ok, view, html} = live(conn, "/")

      # Should show first list
      assert html =~ "Morning Routine"
      assert html =~ "Brush teeth"

      # Switch to second list (this broadcasts to all clients)
      Sessions.set_current_list(task_list2.id)

      # Give the LiveView a moment to receive the PubSub message
      html = render(view)

      # Should now show second list
      assert html =~ "Bedtime Routine"
      assert html =~ "Put on pajamas"
      refute html =~ "Morning Routine"
    end
  end
end
