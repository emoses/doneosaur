defmodule DoneosaurWeb.HomeLive do
  use DoneosaurWeb, :live_view

  alias Doneosaur.{Lists, Clients}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:client_name, nil)
     |> assign(:show_registration, true)
     |> assign(:task_lists, Lists.list_task_lists())}
  end

  @impl true
  def handle_event("client_name_loaded", %{"name" => name}, socket) do
    # Client name found in localStorage, redirect to client page
    {:noreply, push_navigate(socket, to: ~p"/clients/#{name}")}
  end

  @impl true
  def handle_event("register_client", %{"client_name" => name}, socket) do
    name = String.trim(name)

    if name != "" do
      # Create or get the client
      {:ok, _client} = Clients.get_or_create_client(name)

      # Store in socket and redirect
      {:noreply,
       socket
       |> assign(:client_name, name)
       |> push_navigate(to: ~p"/clients/#{name}")}
    else
      {:noreply, socket}
    end
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
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
      }

      .title {
        font-size: 12vh;
        font-weight: bold;
        color: #1f2937;
        margin: 0 0 4vh 0;
        text-align: center;
      }

      .subtitle {
        font-size: 4vh;
        color: #6b7280;
        margin: 0 0 6vh 0;
        text-align: center;
      }

      .registration-card {
        background: white;
        border-radius: 2rem;
        padding: 6vh 6vw;
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
        max-width: 600px;
        width: 100%;
      }

      .form-label {
        font-size: 3vh;
        font-weight: 600;
        color: #1f2937;
        margin-bottom: 2vh;
        display: block;
      }

      .form-input {
        width: 100%;
        font-size: 4vh;
        padding: 2vh;
        border: 3px solid #d1d5db;
        border-radius: 1rem;
        outline: none;
        transition: border-color 0.2s;
      }

      .form-input:focus {
        border-color: #3b82f6;
      }

      .form-button {
        width: 100%;
        font-size: 4vh;
        font-weight: bold;
        padding: 2.5vh;
        margin-top: 3vh;
        background: #3b82f6;
        color: white;
        border: none;
        border-radius: 1rem;
        cursor: pointer;
        transition: background 0.2s;
      }

      .form-button:hover {
        background: #2563eb;
      }

      .form-button:active {
        transform: scale(0.98);
      }
    </style>

    <div
      class="home container"
      phx-hook="ClientStorage"
      id="client-storage-hook"
      data-client-name={@client_name}
    >
      <nav class="tools">
        <a class="btn btn-secondary" href="/admin">⚙ Admin</a>
      </nav>
      <main>
        <h1 class="title">Doneosaur</h1>

        <div :if={@show_registration} class="registration-card">
            <form phx-submit="register_client">
            <label for="client-name-input" class="form-label">Device name</label>
            <input
                type="text"
                id="client-name-input"
                name="client_name"
                class="form-input"
                placeholder="Enter this device's name"
                autofocus
                autocomplete="off"
            />
            <button type="submit" class="form-button">
                Get Started
            </button>
            </form>
        </div>
      </main>
    </div>
    """
  end
end
