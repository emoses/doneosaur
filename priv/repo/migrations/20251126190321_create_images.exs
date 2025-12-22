defmodule Doneosaur.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images, primary_key: false) do
      add :uuid, :binary_id, primary_key: true
      add :name, :string, null: false
      add :type, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:images, [:name])
  end
end
