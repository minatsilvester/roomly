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
          custom_topics={["chat:#{@room.id}"]}
        >
        <%= if @room_activated do %>
          <div class="mt-8 space-y-2">
            <%= for msg <- @messages do %>
              <div class="p-2 bg-gray-100 rounded-md"><%= msg %></div>
            <% end %>
          </div>
          <.form for={%{}} as={:chat} phx-submit="send_message" class="mt-4 flex gap-2">
            <input
              name="chat[message]"
              type="text"
              placeholder="Type your message..."
              class="flex-1 p-2 border border-gray-300 rounded-md"
              autocomplete="off"
            />
            <button
              type="submit"
              class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              Send
            </button>
          </.form>
        <% end %>

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
     |> mount_common_assigns(room.id)
     |> assign(page_title: "Chat Room")
     |> assign(room: room)
     |> assign(server: Roomly.RoomServers.ChatServer)
     |> assign(messages: [])
     |> assign(status: nil)}
  end


  def handle_event("send_message", %{"chat" => %{"message" => message}}, socket) do
    room = socket.assigns.room
    Roomly.RoomServers.ChatServer.append_message(room.id, "#{socket.assigns.current_user.name} : #{message}")
    {:noreply, socket}
  end

  def handle_info({:new_message, message}, socket) do
    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}
  end
end
