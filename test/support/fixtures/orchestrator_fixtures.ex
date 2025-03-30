defmodule Roomly.OrchestratorFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Roomly.Orchestrator` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> Roomly.Orchestrator.create_room()

    room
  end
end
