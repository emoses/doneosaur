defmodule Adhdo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AdhdoWeb.Telemetry,
      Adhdo.Repo,
      {DNSCluster, query: Application.get_env(:adhdo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Adhdo.PubSub},
      {Registry, keys: :unique, name: Adhdo.Sessions.Registry},
      Adhdo.Sessions.Supervisor,
      # Start a worker by calling: Adhdo.Worker.start_link(arg)
      # {Adhdo.Worker, arg},
      # Start to serve requests, typically the last entry
      AdhdoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Adhdo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AdhdoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
