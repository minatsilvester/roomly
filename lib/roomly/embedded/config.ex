defmodule Roomly.Embedded.Config do
  use Ecto.Schema
  import Ecto.Changeset

  # No ID needed since it's embedded
  @primary_key false
  embedded_schema do
    field :work_duration, :integer, default: 25
    field :break_duration, :integer, default: 5
    field :rounds, :integer, default: 4
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:work_duration, :break_duration, :rounds])
  end
end
