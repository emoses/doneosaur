defmodule AdhdoWeb.HomeLive do
  use AdhdoWeb, :live_view

  alias Adhdo.Lists

  @impl true
  def mount(_params, _session, socket) do
    task_lists = Lists.list_task_lists()

    {:ok, assign(socket, :task_lists, task_lists)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <style>
      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        font-family: system-ui, -apple-system, sans-serif;
      }

      .container {
        min-height: 100vh;
        width: 100vw;
        background: linear-gradient(135deg, #e0f2fe 0%, #ddd6fe 100%);
        padding: 4vh 4vw;
      }

      .header {
        text-align: center;
        margin-bottom: 6vh;
      }

      .title {
        font-size: 10vh;
        font-weight: bold;
        color: #1f2937;
        margin: 0 0 2vh 0;
      }

      .subtitle {
        font-size: 4vh;
        color: #6b7280;
        margin: 0;
      }

      .lists-grid {
        max-width: 1200px;
        margin: 0 auto;
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 3vh;
      }

      .list-card {
        background: white;
        border-radius: 1.5rem;
        padding: 4vh 3vw;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        border: 4px solid transparent;
        transition: all 0.2s;
        text-decoration: none;
        color: inherit;
        display: block;
      }

      .list-card:hover {
        box-shadow: 0 10px 15px rgba(0, 0, 0, 0.2);
        transform: translateY(-4px);
        border-color: #93c5fd;
      }

      .list-card:active {
        transform: translateY(-2px);
      }

      .list-name {
        font-size: 5vh;
        font-weight: bold;
        color: #1f2937;
        margin: 0 0 2vh 0;
      }

      .list-description {
        font-size: 3vh;
        color: #6b7280;
        margin: 0 0 2vh 0;
      }

      .list-meta {
        font-size: 2.5vh;
        color: #9ca3af;
        margin: 0;
      }
    </style>

    <div class="container">
      <div class="header">
        <h1 class="title">Adhdo</h1>
        <p class="subtitle">Choose a task list</p>
      </div>

      <div class="lists-grid">
        <a :for={list <- @task_lists} href={~p"/lists/#{list.id}"} class="list-card">
          <h2 class="list-name">{list.name}</h2>
          <p :if={list.description} class="list-description">{list.description}</p>
          <p class="list-meta">
            {length(list.tasks)} {if length(list.tasks) == 1, do: "task", else: "tasks"}
          </p>
        </a>
      </div>
    </div>
    """
  end
end
