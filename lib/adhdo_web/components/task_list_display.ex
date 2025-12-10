defmodule AdhdoWeb.TaskListDisplay do
  @moduledoc """
  Stateless function component for rendering task lists.
  """
  use Phoenix.Component

  alias Adhdo.Lists

  @doc """
  Renders a task list with dynamically sized tasks.

  ## Attributes
    - task_list: The task list struct with name, description, and tasks (required)
    - completed_tasks: MapSet of completed task IDs (required)
  """
  attr :task_list, :map, required: true
  attr :completed_tasks, :map, required: true

  def task_list(assigns) do
    ~H"""
    <div class="container">
      <header>
        <div class="content">
          <h1 class="title">{@task_list.name}</h1>
          <p :if={@task_list.description} class="description">{@task_list.description}</p>
        </div>
        <div class="controls">
          <button phx-click="reset_list">Reset</button>
        </div>
      </header>

      <div class="tasks-container">
        <%= if Enum.all?(@task_list.tasks, fn t -> MapSet.member?(@completed_tasks, t.id) end) do %>
          <.complete/>
        <% else %>
            <div
            :for={task <- @task_list.tasks}
            class={"task-item #{if MapSet.member?(@completed_tasks, task.id), do: "completed", else: ""}"}
            phx-click="toggle_task"
            phx-value-task-id={task.id}
            >
            <% image_url = if task.image_id, do: Lists.get_image_url(task.image), else: nil %>
            <input
                type="checkbox"
                id={"task-#{task.id}"}
                checked={MapSet.member?(@completed_tasks, task.id)}
                class={"task-checkbox #{if image_url, do: "has-image", else: ""}"}
                style={if image_url, do: "background-image: url(#{image_url})", else: ""}
                phx-hook=".TaskCheckSound"
            />
            <label for={"task-#{task.id}"} class="task-label">
                {task.text}
            </label>
            </div>
        <% end %>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".TaskCheckSound">
      export default {

        mounted() {
            this.audio = new Audio('/audio/badink.mp3')
            this.audio.preload = 'auto'

            // Track the previous checked state
            this.wasChecked = this.el.checked
        },
        updated() {
            console.log("Hook")
            const isNowChecked = this.el.checked

            // Only play sound when transitioning from unchecked to checked
            if (!this.wasChecked && isNowChecked) {
                console.log("playing")
                this.audio.currentTime = 0
                this.audio.play().catch(err => {
                    // Ignore errors (e.g., if audio file doesn't exist yet)
                    console.debug('Audio play prevented:', err)
                })
            }

            this.wasChecked = isNowChecked
        }
      }
    </script>
    """
  end

  @doc """
  Renders an "all done" message.
  """
  attr :message, :string, default: "All done!"
  attr :img_url, :string, default: nil

  def complete(assigns) do
    ~H"""
    <div class="complete">
      <img :if={@img_url} src={@img_url} />
      <div class="message">{@message}</div>
    </div>
    """
  end


  @doc """
  Renders a waiting screen when no task list is available.
  """
  attr :message, :string, default: "Waiting for a task list..."
  attr :subtitle, :string, default: nil

  def waiting_screen(assigns) do
    ~H"""
    <div class="waiting-container">
      <p class="waiting-message">{@message}</p>
      <p :if={@subtitle} class="waiting-subtitle">{@subtitle}</p>
    </div>
    """
  end
end
