defmodule RoomlyWeb.RoomLiveTest do
  use RoomlyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Roomly.OrchestratorFixtures
  import Roomly.AccountsFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup %{conn: conn} do
    current_user = user_fixture()
    conn = log_in_user(conn, current_user)
    room = room_fixture_for_user(current_user)
    {:ok, conn: conn, current_user: current_user, room: room}
  end

  describe "Index" do
    test "lists all rooms", %{conn: conn, room: room} do
      {:ok, _index_live, html} = live(conn, ~p"/rooms")

      assert html =~ "Listing Rooms"
      assert html =~ room.name
    end

    test "saves new room", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/rooms")

      assert index_live |> element("a", "New Room") |> render_click() =~
               "New Room"

      assert_patch(index_live, ~p"/rooms/new")

      assert index_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#room-form", room: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/rooms")

      html = render(index_live)
      assert html =~ "Room created successfully"
      assert html =~ "some name"
    end

    test "updates room in listing", %{conn: conn, room: room} do
      {:ok, index_live, _html} = live(conn, ~p"/rooms")

      assert index_live |> element("#rooms-#{room.id} a", "Edit") |> render_click() =~
               "Edit Room"

      assert_patch(index_live, ~p"/rooms/#{room}/edit")

      assert index_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#room-form", room: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/rooms")

      html = render(index_live)
      assert html =~ "Room updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes room in listing", %{conn: conn, room: room} do
      {:ok, index_live, _html} = live(conn, ~p"/rooms")

      assert index_live |> element("#rooms-#{room.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#rooms-#{room.id}")
    end
  end

  describe "Show" do
    # setup [:create_room]

    test "displays room", %{conn: conn, room: room} do
      {:ok, _show_live, html} = live(conn, ~p"/rooms/#{room}")

      assert html =~ "Show Room"
      assert html =~ room.name
    end

    test "updates room within modal", %{conn: conn, room: room} do
      {:ok, show_live, _html} = live(conn, ~p"/rooms/#{room}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Room"

      assert_patch(show_live, ~p"/rooms/#{room}/show/edit")

      assert show_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#room-form", room: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/rooms/#{room}")

      html = render(show_live)
      assert html =~ "Room updated successfully"
      assert html =~ "some updated name"
    end
  end
end
