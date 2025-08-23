defmodule Eatfair.Repo do
  use Ecto.Repo,
    otp_app: :eatfair,
    adapter: Ecto.Adapters.SQLite3
end
