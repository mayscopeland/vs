defmodule Vs.Repo do
  use Ecto.Repo,
    otp_app: :vs,
    adapter: Ecto.Adapters.SQLite3
end
