defmodule DoneosaurWeb.ListControllerTest do
  use DoneosaurWeb.ConnCase

  alias Doneosaur.{Lists, Sessions}

  describe "POST /api/lists/activate" do
    test "activates a task list by name", %{conn: conn} do
      # Create a task list
      {:ok, task_list} =
        Lists.create_task_list_with_tasks(%{
          name: "Morning Routine",
          description: "Tasks for morning",
          tasks: [%{text: "Task 1"}]
        })

      # Make API request
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/lists/activate", %{name: "Morning Routine"})

      # Check response
      assert json_response(conn, 200) == %{
               "success" => true,
               "list" => %{
                 "id" => task_list.id,
                 "name" => "Morning Routine",
                 "description" => "Tasks for morning"
               }
             }

      # Verify the current list was actually set
      assert Sessions.get_current_list() == task_list.id
    end

    test "returns 404 when list name doesn't exist", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/lists/activate", %{name: "Nonexistent List"})

      assert json_response(conn, 404) == %{
               "error" => "Task list not found",
               "name" => "Nonexistent List"
             }
    end

    test "returns 400 when name parameter is missing", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/lists/activate", %{})

      assert json_response(conn, 400) == %{
               "error" => "Missing required field: name"
             }
    end
  end
end
