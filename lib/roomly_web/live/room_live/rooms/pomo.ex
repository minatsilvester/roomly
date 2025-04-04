defmodule RoomlyWeb.RoomLive.Rooms.Pomo do
  use RoomlyWeb, :live_view

  alias Roomly.Orchestrator

  def render(assigns) do
    ~H"""
    <div class="w-[80%] mx-[10%]">
      <.live_component
        module={RoomlyWeb.RoomLive.Components.RoomInfo}
        id="room-info"
        room={@room}
        current_user={@current_user}
        server={Roomly.RoomServers.PomoServer}
      >
        <div class="flex flex-col space-y-6">
          <div class="text-center">
            <%= if @remaining_time do %>
              <span class="text-lg font-semibold text-gray-700">
                {@status |> Atom.to_string() |> String.capitalize()} Mode
              </span>
              <br />
              <br />
              <h3 class="text-3xl font-bold text-blue-600">
                {format_timer(@remaining_time)}
              </h3>
            <% else %>
              <p class="text-gray-500">No active session</p>
            <% end %>
          </div>

          <div class="flex flex-col items-center justify-center space-y-4">
            <.button
              phx-click="start_timer"
              class="w-32 bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded"
            >
              Start Timer
            </.button>

            <.button
              phx-click="stop_timer"
              class="w-32 bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded"
            >
              Stop Timer
            </.button>
          </div>
        </div>
      </.live_component>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    room = Orchestrator.get_room!(id)

    {:noreply,
     socket
     |> assign(page_title: "Pomo Room")
     |> assign(room: room)
     |> assign(remaining_time: nil)
     |> assign(status: nil)}
  end

  def handle_event("start_timer", _params, socket) do
    room = socket.assigns.room
    Roomly.RoomServers.PomoServer.start_timer(room.id)
    {:noreply, put_flash(socket, :info, "Timer Started")}
  end

  def handle_event("stop_timer", _params, socket) do
    room = socket.assigns.room
    Roomly.RoomServers.PomoServer.stop_timer(room.id, room.config)
    {:noreply, put_flash(socket, :info, "Timer Stopped")}
  end

  def handle_info({:timer_update, time, status}, socket) do
    {:noreply, assign(socket, remaining_time: time, status: status)}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{topic: "room:" <> _, event: "presence_diff", payload: payload},
        socket
      ) do
    send_update(RoomlyWeb.RoomLive.Components.RoomInfo, id: "room-info", payload: payload)

    {:noreply, socket}
  end

  def handle_info({:room_activation, room_activated}, socket) do
    send_update(RoomlyWeb.RoomLive.Components.RoomInfo,
      id: "room-info",
      room_activated: room_activated
    )

    {:noreply, socket}
  end

  defp format_timer(remaining_time) do
    "#{div(remaining_time, 60)}:#{rem(remaining_time, 60)}"
  end
end
