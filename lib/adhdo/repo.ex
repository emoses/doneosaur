defmodule Adhdo.Repo do
  use Ecto.Repo,
    otp_app: :adhdo,
    adapter: Ecto.Adapters.SQLite3
end
