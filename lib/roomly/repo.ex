defmodule Roomly.Repo do
  use Ecto.Repo,
    otp_app: :roomly,
    adapter: Ecto.Adapters.Postgres
end
