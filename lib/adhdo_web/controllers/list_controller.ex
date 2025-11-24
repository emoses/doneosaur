defmodule AdhdoWeb.ListController do
  use AdhdoWeb, :controller

  alias Adhdo.{Lists, Sessions}

  @doc """
  POST /api/lists/activate
  Body: {"name": "Morning Routine"}

  Sets the specified list as the current active list by name.
  All connected clients will switch to this list.
  """
  def activate(conn, %{"name" => list_name}) do
    case Lists.get_task_list_by_name(list_name) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Task list not found", name: list_name})

      task_list ->
        :ok = Sessions.set_current_list(task_list.id)

        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          list: %{
            id: task_list.id,
            name: task_list.name,
            description: task_list.description
          }
        })
    end
  end

  def activate(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required field: name"})
  end
end
