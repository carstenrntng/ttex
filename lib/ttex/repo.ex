defmodule Ttex.Repo do
  use Ecto.Repo,
    otp_app: :ttex,
    adapter: Ecto.Adapters.SQLite3
end
