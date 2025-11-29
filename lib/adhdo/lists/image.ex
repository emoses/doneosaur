defmodule Adhdo.Lists.Image do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  schema "images" do
    field :name, :string
    field :type, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:name, :type])
    |> normalize_type()
    |> validate_required([:name, :type])
    |> validate_inclusion(:type, ["png", "jpeg", "gif", "webp"])
  end

  defp normalize_type(changeset) do
    case get_change(changeset, :type) do
      "jpg" -> put_change(changeset, :type, "jpeg")
      _ -> changeset
    end
  end
end
