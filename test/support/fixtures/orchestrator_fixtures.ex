defmodule Roomly.OrchestratorFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Roomly.Orchestrator` context.
  """
  alias Roomly.Accounts

  @doc """
  Generate a room.
  """
  def room_fixture_for_user(user) do
    {:ok, room} =
      %{}
      |> Enum.into(%{
        "description" => "some description",
        "name" => "some name",
        "type" => "pomodoro",
        "config" => %{
          "work_duration" => 25,
          "break_duration" => 10,
          "rounds" => 5
        }
      })
      |> Roomly.Orchestrator.create_room(user)

    room
  end

  def room_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "testuser@mail.com",
        password: "Silver@270599"
      })
      |> Accounts.register_user()

    {:ok, room} =
      attrs
      |> Enum.into(%{
        "description" => "some description",
        "name" => "some name",
        "type" => "pomodoro",
        "config" => %{
          "work_duration" => 25,
          "break_duration" => 10,
          "rounds" => 5
        }
      })
      |> Roomly.Orchestrator.create_room(user)

    room
  end

  def get_user_for_room(room) do
    Accounts.get_user!(room.user_id)
  end
end
