defmodule Roomly.OrchestratorTest do
  use Roomly.DataCase

  alias Roomly.Orchestrator

  describe "rooms" do
    alias Roomly.Orchestrator.Room

    import Roomly.OrchestratorFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Orchestrator.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Orchestrator.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Room{} = room} = Orchestrator.create_room(valid_attrs)
      assert room.name == "some name"
      assert room.description == "some description"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orchestrator.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Room{} = room} = Orchestrator.update_room(room, update_attrs)
      assert room.name == "some updated name"
      assert room.description == "some updated description"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Orchestrator.update_room(room, @invalid_attrs)
      assert room == Orchestrator.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Orchestrator.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Orchestrator.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Orchestrator.change_room(room)
    end
  end
end
