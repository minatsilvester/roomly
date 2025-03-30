defmodule RoomlyWeb.RoomLive.Index do
  use RoomlyWeb, :live_view

  alias Roomly.Orchestrator
  alias Roomly.Orchestrator.Room

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :rooms, Orchestrator.list_rooms_for_user(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Orchestrator.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rooms")
    |> assign(:room, nil)
  end

  @impl true
  def handle_info({RoomlyWeb.RoomLive.FormComponent, {:saved, room}}, socket) do
    {:noreply, stream_insert(socket, :rooms, room)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Orchestrator.get_room!(id)
    {:ok, _} = Orchestrator.delete_room(room)

    {:noreply, stream_delete(socket, :rooms, room)}
  end
end
