defmodule Doneosaur.Repo.Migrations.DropClientsTable do
  use Ecto.Migration

  def change do
    drop table(:clients)
  end
end
