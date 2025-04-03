defmodule RoomlyWeb.Rooms.PomoTest do
  use RoomlyWeb.ConnCase

  import Roomly.OrchestratorFixtures
  import Roomly.AccountsFixtures

  setup %{conn: conn} do
    current_user = user_fixture()
    conn = log_in_user(conn, current_user)
    room = room_fixture_for_user(current_user)
    {:ok, conn: conn, current_user: current_user, room: room}
  end
end
