defmodule AdhdoWeb.Admin.FormLive do
  use AdhdoWeb, :live_view

  alias Adhdo.Lists
  alias Adhdo.Lists.TaskList
  alias Adhdo.Sessions

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:images, Lists.list_images())
     |> assign(:selected_task_index, nil)
     |> allow_upload(:image,
       accept: ~w(.png .jpg .jpeg .gif .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
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
      image_id: nil,
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

  @impl true
  def handle_event("open_image_picker", %{"index" => index}, socket) do
    {:noreply, assign(socket, :selected_task_index, String.to_integer(index))}
  end

  @impl true
  def handle_event("close_image_picker", _params, socket) do
    {:noreply, assign(socket, :selected_task_index, nil)}
  end

  @impl true
  def handle_event("prevent_close", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_existing_image", %{"uuid" => uuid}, socket) do
    index = socket.assigns.selected_task_index

    tasks =
      List.update_at(socket.assigns.tasks, index, fn task ->
        %{task | image_id: uuid}
      end)

    {:noreply,
     socket
     |> assign(:tasks, tasks)
     |> assign(:selected_task_index, nil)}
  end

  @impl true
  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  @impl true
  def handle_event("save_uploaded_image", %{"name" => name}, socket) do
    index = socket.assigns.selected_task_index

    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        # Determine file type from entry
        type =
          entry.client_type
          |> String.split("/")
          |> List.last()
          |> String.downcase()

        # Create image record
        {:ok, image} = Lists.create_image(%{name: name, type: type})

        # Save file to disk
        dest_dir = Application.get_env(:adhdo, :image_storage_path, "priv/static/images/tasks")
        File.mkdir_p!(dest_dir)
        dest = Path.join(dest_dir, "#{image.uuid}.#{type}")
        File.cp!(path, dest)

        {:ok, image.uuid}
      end)

    case uploaded_files do
      [uuid | _] ->
        tasks =
          List.update_at(socket.assigns.tasks, index, fn task ->
            %{task | image_id: uuid}
          end)

        {:noreply,
         socket
         |> assign(:tasks, tasks)
         |> assign(:images, Lists.list_images())
         |> assign(:selected_task_index, nil)}

      [] ->
        {:noreply, socket}
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
        %{text: task.text, image_id: Map.get(task, :image_id)}
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
                  <div class="image-picker-control">
                    <%= if task.image_id do %>
                      <% image = Enum.find(@images, fn img -> img.uuid == task.image_id end) %>
                      <%= if image do %>
                        <div class="selected-image">
                          <img src={Lists.get_image_url(image)} alt={image.name} />
                          <span>{image.name}</span>
                        </div>
                      <% else %>
                        <span class="text-muted">Image ID: {task.image_id} (not found)</span>
                      <% end %>
                    <% end %>
                    <button
                      type="button"
                      phx-click="open_image_picker"
                      phx-value-index={index}
                      class="btn btn-secondary"
                    >
                      {if task.image_id,
                        do: "Change Image (#{task.image_id |> String.slice(0..7)})",
                        else: "Add Image"}
                    </button>
                  </div>
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
          <div style="display: flex; justify-content: space-between; align-items: center;">
            <button type="button" phx-click="add_task" class="btn">
              + Add Task
            </button>
          </div>
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

      <%= if @selected_task_index != nil do %>
        <div class="image-picker-modal" phx-click="close_image_picker">
          <div class="image-picker-content" phx-click="prevent_close">
            <div class="image-picker-header">
              <h2>Select or Upload Image</h2>
              <button type="button" phx-click="close_image_picker" class="btn-close">✕</button>
            </div>

            <div class="image-picker-body">
              <div class="existing-images">
                <h3>Existing Images</h3>
                <div class="image-grid">
                  <%= for image <- @images do %>
                    <div
                      class="image-grid-item"
                      phx-click="select_existing_image"
                      phx-value-uuid={image.uuid}
                    >
                      <img src={Lists.get_image_url(image)} alt={image.name} />
                      <span>{image.name}</span>
                    </div>
                  <% end %>
                  <%= if @images == [] do %>
                    <p class="text-muted">No images yet. Upload one below.</p>
                  <% end %>
                </div>
              </div>

              <div class="upload-section">
                <h3>Upload New Image</h3>
                <form phx-submit="save_uploaded_image" phx-change="validate_upload">
                  <div class="form-group">
                    <label class="form-label">Image Name</label>
                    <input
                      type="text"
                      name="name"
                      class="form-input"
                      placeholder="e.g., Brush Teeth"
                      required
                    />
                  </div>

                  <div class="upload-drop-zone" phx-drop-target={@uploads.image.ref}>
                    <div :for={entry <- @uploads.image.entries} class="upload-entry">
                      <figure>
                        <.live_img_preview entry={entry} />
                        <figcaption>{entry.client_name}</figcaption>
                      </figure>
                      <button
                        type="button"
                        phx-click="cancel_upload"
                        phx-value-ref={entry.ref}
                        class="btn btn-danger"
                      >
                        Cancel
                      </button>
                    </div>
                    <.live_file_input upload={@uploads.image} />
                    <p>Click to select or drag and drop an image</p>
                  </div>

                  <%= for err <- upload_errors(@uploads.image) do %>
                    <p class="form-error">{error_to_string(err)}</p>
                  <% end %>

                  <button
                    type="submit"
                    class="btn btn-primary"
                    disabled={@uploads.image.entries == []}
                  >
                    Upload and Select
                  </button>
                </form>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:not_accepted), do: "Invalid file type"
  defp error_to_string(_), do: "Upload error"
end
