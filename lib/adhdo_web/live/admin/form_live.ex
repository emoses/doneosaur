defmodule AdhdoWeb.Admin.FormLive do
  use AdhdoWeb, :live_view

  alias Adhdo.Lists
  alias Adhdo.Lists.TaskList
  alias Adhdo.Sessions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Task List")
    |> assign(:task_list, %TaskList{tasks: []})
    |> assign(:changeset, Lists.change_task_list(%TaskList{}))
    |> assign(:tasks, [])
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    task_list = Lists.get_task_list!(String.to_integer(id))

    socket
    |> assign(:page_title, "Edit Task List")
    |> assign(:task_list, task_list)
    |> assign(:changeset, Lists.change_task_list(task_list))
    |> assign(:tasks, task_list.tasks)
  end

  @impl true
  def handle_event("validate", %{"task_list" => task_list_params}, socket) do
    changeset =
      socket.assigns.task_list
      |> Lists.change_task_list(task_list_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"task_list" => task_list_params}, socket) do
    save_task_list(socket, socket.assigns.live_action, task_list_params)
  end

  @impl true
  def handle_event("add_task", _params, socket) do
    new_task = %{
      id: "new_#{System.unique_integer([:positive])}",
      text: "",
      image_url: nil,
      temp_id: true
    }

    {:noreply, assign(socket, :tasks, socket.assigns.tasks ++ [new_task])}
  end

  @impl true
  def handle_event("remove_task", %{"index" => index}, socket) do
    index = String.to_integer(index)
    tasks = List.delete_at(socket.assigns.tasks, index)

    {:noreply, assign(socket, :tasks, tasks)}
  end

  @impl true
  def handle_event("update_task_text", %{"index" => index, "value" => value}, socket) do
    index = String.to_integer(index)
    tasks = List.update_at(socket.assigns.tasks, index, fn task -> %{task | text: value} end)

    {:noreply, assign(socket, :tasks, tasks)}
  end

  @impl true
  def handle_event("update_task_image", %{"index" => index, "value" => value}, socket) do
    index = String.to_integer(index)
    image_url = if value == "", do: nil, else: value

    tasks =
      List.update_at(socket.assigns.tasks, index, fn task -> %{task | image_url: image_url} end)

    {:noreply, assign(socket, :tasks, tasks)}
  end

  @impl true
  def handle_event("move_task_up", %{"index" => index}, socket) do
    index = String.to_integer(index)

    if index > 0 do
      tasks = swap_tasks(socket.assigns.tasks, index, index - 1)
      {:noreply, assign(socket, :tasks, tasks)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move_task_down", %{"index" => index}, socket) do
    index = String.to_integer(index)
    tasks = socket.assigns.tasks

    if index < length(tasks) - 1 do
      tasks = swap_tasks(tasks, index, index + 1)
      {:noreply, assign(socket, :tasks, tasks)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reorder_task", %{"from" => from_index, "to" => to_gap}, socket) do
    insert_pos = if from_index < to_gap, do: to_gap - 1, else: to_gap

    if from_index == insert_pos do
      {:noreply, socket}
    else
      tasks = socket.assigns.tasks
      {item, tasks} = List.pop_at(tasks, from_index)

      # to_gap is the target gap index (0 to n, where n is number of items)
      # After removing the item, we need to adjust the insertion position
      # If from_index < to_gap, the gap shifts down by 1 after removal

      tasks = List.insert_at(tasks, insert_pos, item)

      {:noreply, assign(socket, :tasks, tasks)}
    end
  end

  defp swap_tasks(tasks, index_a, index_b) do
    task_a = Enum.at(tasks, index_a)
    task_b = Enum.at(tasks, index_b)

    tasks
    |> List.replace_at(index_a, task_b)
    |> List.replace_at(index_b, task_a)
  end

  defp save_task_list(socket, :new, task_list_params) do
    # Prepare tasks
    task_attrs =
      socket.assigns.tasks
      |> Enum.filter(fn task -> task.text && String.trim(task.text) != "" end)
      |> Enum.map(fn task ->
        %{text: task.text, image_url: task.image_url}
      end)

    attrs = Map.put(task_list_params, :tasks, task_attrs)

    case Lists.create_task_list_with_tasks(attrs) do
      {:ok, task_list} ->
        if Sessions.session_exists?(task_list.id) do
            Sessions.reset_session(task_list.id)
        end

        {:noreply,
         socket
         |> put_flash(:info, "Task list created successfully")
         |> push_navigate(to: ~p"/admin")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_task_list(socket, :edit, task_list_params) do
    task_list = socket.assigns.task_list

    # Update task list basic info
    case Lists.update_task_list_and_tasks(task_list, task_list_params, socket.assigns.tasks) do
      {:ok, _updated_list} ->
        Sessions.reload_list(task_list.id)

        {:noreply,
         socket
         |> put_flash(:info, "Task list updated successfully")
         |> push_navigate(to: ~p"/admin")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="admin-container">
      <div class="admin-header">
        <h1>{@page_title}</h1>
        <.link navigate={~p"/admin"} class="btn btn-secondary">
          Back
        </.link>
      </div>

      <.form
        for={@changeset}
        id="task-list-form"
        phx-change="validate"
        phx-submit="save"
        class="card"
      >
        <div class="form-group">
          <label for="task_list_name" class="form-label">Name</label>
          <input
            type="text"
            name="task_list[name]"
            id="task_list_name"
            value={Ecto.Changeset.get_field(@changeset, :name)}
            class="form-input"
            required
          />
        </div>

        <div class="form-group">
          <label for="task_list_description" class="form-label">Description</label>
          <textarea
            name="task_list[description]"
            id="task_list_description"
            class="form-textarea"
          >{Ecto.Changeset.get_field(@changeset, :description)}</textarea>
        </div>

        <div class="form-group">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem;">
            <label class="form-label" style="margin-bottom: 0;">Tasks</label>
            <button type="button" phx-click="add_task" class="btn btn-secondary">
              Add Task
            </button>
          </div>

          <%= if @tasks == [] do %>
            <p class="text-muted">No tasks yet. Click "Add Task" to create one.</p>
          <% else %>
            <div id="task-list-container" phx-hook="DragDropTaskList">
              <div
                :for={{task, index} <- Enum.with_index(@tasks)}
                class="task-list-item"
                id={"task-#{task.id}"}
                data-index={index}
              >
                <div class="drag-handle" title="Drag to reorder">⋮⋮</div>
                <div class="task-list-item-text">
                  <input
                    type="text"
                    id={"task-text-#{task.id}"}
                    value={task.text}
                    phx-blur="update_task_text"
                    phx-value-index={index}
                    class="form-input"
                    placeholder="Task description"
                    style="margin-bottom: 0.5rem;"
                  />
                  <input
                    type="text"
                    id={"task-image-#{task.id}"}
                    value={task.image_url || ""}
                    phx-blur="update_task_image"
                    phx-value-index={index}
                    class="form-input"
                    placeholder="Image URL (optional)"
                  />
                </div>
                <div class="task-list-item-actions">
                  <button
                    type="button"
                    phx-click="move_task_up"
                    phx-value-index={index}
                    class="btn btn-secondary"
                    disabled={index == 0}
                  >
                    ↑
                  </button>
                  <button
                    type="button"
                    phx-click="move_task_down"
                    phx-value-index={index}
                    class="btn btn-secondary"
                    disabled={index == length(@tasks) - 1}
                  >
                    ↓
                  </button>
                  <button
                    type="button"
                    phx-click="remove_task"
                    phx-value-index={index}
                    class="btn btn-danger"
                  >
                    ✕
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn btn-primary">
            Save Task List
          </button>
          <.link navigate={~p"/admin"} class="btn btn-secondary">
            Cancel
          </.link>
        </div>
      </.form>
    </div>
    """
  end
end
