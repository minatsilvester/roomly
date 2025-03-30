defmodule Roomly.Orchestrator.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    field :description, :string
    field :type, :string
    belongs_to :user, Roomly.Accounts.User
    embeds_one :config, Roomly.Embedded.Config

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :description, :user_id, :type])
    |> validate_required([:name, :user_id, :type])
    |> validate_inclusion(:type, ["pomodoro", "music"])
    |> cast_embed(:config, with: &Roomly.Embedded.Config.changeset/2)
  end
end
