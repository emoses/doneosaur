defmodule Doneosaur.Repo do
  use Ecto.Repo,
    otp_app: :doneosaur,
    adapter: Ecto.Adapters.SQLite3
end
