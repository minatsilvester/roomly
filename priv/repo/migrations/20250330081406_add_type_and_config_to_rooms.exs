defmodule Roomly.Repo.Migrations.AddTypeAndConfigToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :type, :string
      add :config, :map, default: %{}
    end
  end
end
