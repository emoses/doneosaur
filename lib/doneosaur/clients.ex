defmodule Doneosaur.Clients do
  @moduledoc """
  The Clients context manages client device registration.
  """

  alias Doneosaur.Repo
  alias Doneosaur.Clients.Client

  @doc """
  Gets or creates a client by name.
  """
  def get_or_create_client(name) do
    case Repo.get_by(Client, name: name) do
      nil ->
        %Client{}
        |> Client.changeset(%{name: name})
        |> Repo.insert()

      client ->
        {:ok, client}
    end
  end

  @doc """
  Gets a client by name.
  """
  def get_client_by_name(name) do
    Repo.get_by(Client, name: name)
  end

  @doc """
  Lists all clients.
  """
  def list_clients do
    Repo.all(Client)
  end
end
