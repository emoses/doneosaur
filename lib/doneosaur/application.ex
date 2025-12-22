defmodule Doneosaur.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DoneosaurWeb.Telemetry,
      Doneosaur.Repo,
      {DNSCluster, query: Application.get_env(:doneosaur, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Doneosaur.PubSub},
      {Registry, keys: :unique, name: Doneosaur.Sessions.Registry},
      Doneosaur.Sessions.Supervisor,
      %{
        id: Doneosaur.Sessions,
        start: {Doneosaur.Sessions, :start_link, [[]]}
      },
      # Scheduler for activating task lists at scheduled times
      Doneosaur.Scheduler,
      # Start to serve requests, typically the last entry
      DoneosaurWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Doneosaur.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DoneosaurWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
