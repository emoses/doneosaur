defmodule AdhdoWeb.ClientLiveTest do
  use AdhdoWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Adhdo.{Lists, Sessions}

  describe "ClientLive" do
    test "renders waiting screen when no current list is set", %{conn: conn} do
      # Ensure there's no current list
      Sessions.set_current_list(nil)

      {:ok, _view, html} = live(conn, "/clients/test-client")

      # Should show waiting screen with client name
      assert html =~ "Hi test-client!"
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

      {:ok, _view, html} = live(conn, "/clients/test-client")

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

      {:ok, view, html} = live(conn, "/clients/test-client")

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

    test "creates client record when mounting", %{conn: conn} do
      # Ensure no current list so mount doesn't try to load one
      Sessions.set_current_list(nil)

      client_name = "new-client-#{System.unique_integer([:positive])}"

      {:ok, _view, _html} = live(conn, "/clients/#{client_name}")

      # Client should be created
      assert {:ok, client} = Adhdo.Clients.get_or_create_client(client_name)
      assert client.name == client_name
    end
  end
end
