defmodule AdhdoWeb.Admin.IndexLive do
  use AdhdoWeb, :live_view

  alias Adhdo.{Lists, Sessions}
  alias Adhdo.Lists.Schedule

  @impl true
  def mount(_params, _session, socket) do
    task_lists = Lists.list_task_lists()
    current_list_id = Sessions.get_current_list()

    {:ok,
     socket
     |> assign(:task_lists, task_lists)
     |> assign(:current_list_id, current_list_id)
     |> assign(:sched_task_list, nil)}
  end

  @impl true
  def handle_event("set_current_list", %{"list-id" => list_id}, socket) do
    list_id = String.to_integer(list_id)
    :ok = Sessions.set_current_list(list_id)

    {:noreply,
     socket
     |> assign(:current_list_id, list_id)
     |> put_flash(:info, "Current list updated successfully")}
  end

  @impl true
  def handle_event("sched_task_list", %{"list-id" => list_id}, socket) do
    list_id = String.to_integer(list_id)
    {:noreply,
     socket
     |> assign(:sched_task_list, list_id)}
  end

  @impl true
  def handle_event("hide-scheduler", _, socket) do
    {:noreply,
     socket
     |> assign(:sched_task_list, nil)}
  end

  @impl true
  def handle_event("delete_list", %{"list-id" => list_id}, socket) do
    list_id = String.to_integer(list_id)
    task_list = Lists.get_task_list!(list_id)

    case Lists.delete_task_list(task_list) do
      {:ok, _} ->
        task_lists = Lists.list_task_lists()

        # If we deleted the current list, clear it
        current_list_id =
          if socket.assigns.current_list_id == list_id do
            Sessions.set_current_list(nil)
            nil
          else
            socket.assigns.current_list_id
          end

        {:noreply,
         socket
         |> assign(:task_lists, task_lists)
         |> assign(:current_list_id, current_list_id)
         |> put_flash(:info, "Task list deleted successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete task list")}
    end
  end

  @impl true
  def handle_event("delete_sched", %{"sched-id" => sched_id}, socket) do
    sched = Lists.get_schedule!(sched_id)

    case Lists.delete_schedule(sched) do
      {:ok, _} ->
        {:noreply,
          socket
          |> assign(:task_lists, reload_task_list!(socket.assigns.task_lists, sched.task_list_id))}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete sched")}
    end
  end

  @impl true
  def handle_event("create-scheds", vals, socket) do
    # create-scheds will receive a map like this
    # %{
    #   "day2" => "on",
    #   "day5" => "on",
    #   "task_list_id" => "12",
    #   "time-input" => "03:00"
    # }
    attrs = for x <- 1..7 do
              if Map.get(vals, "day#{x}", "off") == "on" do
                %{
                  day_of_week: x,
                  time: vals["time-input"],
                  task_list_id: vals["task_list_id"],
                }
              end
    end
    |> Enum.reject(&is_nil/1)

    IO.inspect(attrs)

    case Lists.create_schedules(attrs) do
      {:ok, _} ->
        task_list_id = String.to_integer(vals["task_list_id"])
        {:noreply,
          socket
          |> assign(:task_lists, reload_task_list!(socket.assigns.task_lists, task_list_id))
          |> assign(:sched_task_list, nil)
        }
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to create new sched")}
    end
  end

  defp reload_task_list!(task_lists, id) do
    case Enum.find_index(task_lists, fn l -> l.id == id end) do
      nil -> raise "List with id #{id} not found"
      i ->
        newlist = Lists.get_task_list!(id)
        List.replace_at(task_lists, i, newlist)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="admin-container">
      <div class="admin-header">
        <h1>Task Lists</h1>
        <.link navigate={~p"/admin/lists/new"} class="btn btn-primary">
          New Task List
        </.link>
      </div>

      <%= if @task_lists == [] do %>
        <div class="empty-state">
          <p>No task lists yet</p>
          <.link navigate={~p"/admin/lists/new"} class="btn btn-primary">
            Create your first task list
          </.link>
        </div>
      <% else %>
        <div>
          <div :for={list <- @task_lists} class="card">
            <div class="card-header">
              <div style="flex: 1">
                <h2 class="card-title">
                  {list.name}
                  <%= if list.id == @current_list_id do %>
                    <span class="badge badge-success">Current List</span>
                  <% end %>
                </h2>
                <p :if={list.description} class="card-description">{list.description}</p>
                <p class="text-muted">
                  {length(list.tasks)} {if length(list.tasks) == 1, do: "task", else: "tasks"}
                </p>
              </div>

              <div class="card-actions">
                <%= if list.id != @current_list_id do %>
                  <button
                    phx-click="set_current_list"
                    phx-value-list-id={list.id}
                    class="btn btn-secondary"
                  >
                    Set as Current
                  </button>
                <% end %>
                <.link navigate={~p"/admin/lists/#{list.id}/edit"} class="btn btn-secondary">
                  Edit
                </.link>
                <button phx-click="sched_task_list"
                  phx-value-list-id={list.id}
                  class="btn btn-secondary">
                  Schedule
                </button>
                <button
                  phx-click="delete_list"
                  phx-value-list-id={list.id}
                  data-confirm="Are you sure you want to delete this task list?"
                  class="btn btn-danger"
                >
                  Delete
                </button>
              </div>
            </div>
            <.schedule schedules={list.schedules}/>

          </div>
        </div>
      <% end %>
    </div>
    <.schedule_picker :if={@sched_task_list}
      task_list_id={@sched_task_list}
      title={Enum.find(@task_lists, fn t -> t.id == @sched_task_list end) |> Map.get(:name)} />
    """
  end

  attr :schedules, :list, required: true
  defp schedule(%{schedules: schedules} = assigns) do
    assigns = assign(assigns, :day_scheds, Enum.group_by(schedules, &(&1.day_of_week)))
    ~H"""
    <div class="schedule">
      <div :for={day <- 1..7} class="day">
        <div class="dayName">{Lists.Schedule.day_name(day)}</div>
        <div class="blockList">
          <div :for={sched <- Map.get(@day_scheds, day, [])} class="block">
            {Calendar.strftime(sched.time, "%-I:%M %p")}
            <button
              phx-click="delete_sched"
              phx-value-sched-id={sched.id}
              class="sched-delete"
            >
              ×
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :task_list_id, :string, required: true
  attr :title, :string
  defp schedule_picker(assigns) do
    ~H"""
    <dialog
      id="scheduler"
      class="scheduler"
      phx-remove={JS.dispatch("hide-dialog", to: "#scheduler")}
      phx-mounted={JS.dispatch("show-dialog", to: "#scheduler")}
      phx-updated={JS.dispatch("show-dialog", to: "#scheduler")}
      phx-window-keydown={JS.push("hide-scheduler")}
      phx-key="escape"
    >
      <button
        type="button"
        class="close-button"
        phx-click={JS.push("hide-scheduler")}
        aria-label="Close"
      >
        ×
      </button>
      <form phx-submit="create-scheds">
        <h1 :if={@title}>Add schedule for {@title}</h1>
        <input type="hidden" name="task_list_id" value={@task_list_id}/>
        <div class="days">
            <div :for={day <- 1..7} class="day">
                <label for={"scheduler-day#{day}"}>{Lists.Schedule.day_name(day)}</label>
                <input type="checkbox" id={"scheduler-day#{day}"} name={"day#{day}"}/>
            </div>
        </div>

        <div class="time">
            <label for="time-input">Time</label>
            <input name="time-input" type="time" required/>
        </div>

        <div class="button-group">
          <button type="submit" class="btn-submit">Create</button>
          <button
            type="button"
            class="btn-cancel"
            phx-click={JS.push("hide-scheduler")}
          >
            Cancel
          </button>
        </div>
      </form>
    </dialog>
    """
  end
end
