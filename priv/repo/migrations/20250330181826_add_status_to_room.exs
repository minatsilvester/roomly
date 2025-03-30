defmodule Roomly.Repo.Migrations.AddStatusToRoom do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :status, :string
    end
  end
end
