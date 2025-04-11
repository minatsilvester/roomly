defmodule RoomlyWeb.RoomLive.Rooms.Chat do
  use RoomlyWeb, :live_view
  use RoomlyWeb.RoomLive

  alias Roomly.Orchestrator

  def render(assigns) do
    ~H"""
    <div class="w-full px-4 py-32 sm:px-6 lg:px-8">
    <div class="w-[80%] mx-[10%]">
      <.live_component
        module={RoomlyWeb.RoomLive.Components.RoomInfo}
        id="room-info"
        room={@room}
        current_user={@current_user}
        server={@server}
      >
      </.live_component>
    </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    room = Orchestrator.get_room!(id)

    {:noreply,
     socket
     |> assign(page_title: "Pomo Room")
     |> assign(room: room)
     |> assign(server: Roomly.RoomServers.ChatServer)
     |> assign(messages: [])
     |> assign(status: nil)}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    room = socket.assigns.room
    Roomly.RoomServers.ChatServer.append_message(room.id, message)
    {:noreply, socket}
  end

  def handle_info({:new_message, message}, socket) do
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}
  end
end
