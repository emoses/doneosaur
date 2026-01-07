defmodule DoneosaurWeb.TaskListDisplay do
  @moduledoc """
  Stateless function component for rendering task lists.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  alias Doneosaur.Lists

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
      <audio id="task-sound" preload="auto">
        <source src="/audio/badink.mp3" type="audio/mpeg">
      </audio>
      <audio id="success-sound" preload="auto">
        <source src="/audio/success.wav" type="audio/wav">
      </audio>
      <script>
        window.addEventListener('doneosaur:task_toggled', (e) => {
          // Optimistic: play the sound if checked is *false*, because we're about to check it
          if (e.detail && e.detail.remaining <= 1) {
            const audio = document.getElementById('success-sound');
            audio.currentTime = 0;
            audio.play().catch(err => console.debug('Audio play prevented:', err));
          } else if (!e.detail.checked) {
            const audio = document.getElementById('task-sound');
            audio.currentTime = 0;
            audio.play().catch(err => console.debug('Audio play prevented:', err));
          }
        });
      </script>

      <header>
        <div class="left-controls">
          <a href="/admin">⚙</a>
        </div>
        <div class="content">
          <h1 class="title">{@task_list.name}</h1>
          <p :if={@task_list.description} class="description">{@task_list.description}</p>
        </div>
        <div class="controls">
          <button class="btn btn-secondary" phx-click="reset_list">
            <span class="btn-icon">🔄</span>
            Reset
          </button>
        </div>
      </header>

      <div class="tasks-container" style={"--n-tasks: #{length(@task_list.tasks)}"}>
        <%= if Enum.all?(@task_list.tasks, fn t -> MapSet.member?(@completed_tasks, t.id) end) do %>
          <.complete>All<br/>Done!</.complete>
        <% else %>
            <div
            :for={task <- @task_list.tasks}
            class={"task-item #{if MapSet.member?(@completed_tasks, task.id), do: "completed", else: ""}"}
            phx-click={
              JS.dispatch("doneosaur:task_toggled", detail: %{
                remaining: length(@task_list.tasks) - MapSet.size(@completed_tasks),
                checked: MapSet.member?(@completed_tasks, task.id),
              })
              |> JS.push("toggle_task", value: %{"task-id": task.id})
            }
            >
            <% image_url = if task.image_id, do: Lists.get_image_url(task.image), else: nil %>
            <input
                type="checkbox"
                id={"task-#{task.id}"}
                checked={MapSet.member?(@completed_tasks, task.id)}
                class={"task-checkbox #{if image_url, do: "has-image", else: ""}"}
                style={if image_url, do: "background-image: url(#{image_url})", else: ""}
            />
            <label for={"task-#{task.id}"} class="task-label">
                {task.text}
            </label>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :img_url, :string, default: nil
  defp complete(assigns) do
    ~H"""
    <div class="complete" id="complete" phx-hook=".PlayComplete">
      <img :if={@img_url} src={@img_url} />
      <div class="message">{render_slot(@inner_block)}</div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PlayComplete">
      export default {
        mounted() {
            this.audio = document.getElementById('success-sound');
            this.audio.currentTime = 0;
            this.audio.play().catch(err => console.debug('Audio play prevented:', err));
        },

        destroyed() {
           if (this.audio) {
              this.audio.pause();
           }
        }
      };
    </script>
    """
  end


  @doc """
  Renders a waiting screen when no task list is available.
  """
  attr :message, :string, default: "Waiting for a task list..."
  attr :subtitle, :string, default: nil

  def waiting_screen(assigns) do
    ~H"""
    <div class="container waiting">
      <header>
        <div class="left-controls">
          <a href="/admin">⚙</a>
        </div>
      </header>
      <p class="waiting-message">{@message}</p>
      <p :if={@subtitle} class="waiting-subtitle">{@subtitle}</p>
    </div>
    """
  end
end
