defmodule RoomlyWeb.RoomLive do
  defmacro __using__(_opts) do
    quote do
      def handle_info({:users_diff, payload}, socket) do
        send_update(RoomlyWeb.RoomLive.Components.RoomInfo, id: "room-info", payload: payload)

        {:noreply, socket}
      end

      def handle_info({:room_activation, room_activated}, socket) do
        send_update(RoomlyWeb.RoomLive.Components.RoomInfo,
          id: "room-info",
          room_activated: room_activated
        )

        {:noreply, assign(socket, :room_activated, room_activated)}
      end

      def terminate(
            _reason,
            %{assigns: %{server: server, room: room, current_user: current_user}} = _socket
          ) do
        server.leave(room.id, current_user.id)
        Phoenix.PubSub.unsubscribe(Roomly.PubSub, "room:#{room.id}")
        :ok
      end

      def mount_common_assigns(socket, room_id) do
        room_activated = Registry.lookup(Roomly.RoomRegistry, room_id) != []
        assign(socket, :room_activated, room_activated)
      end
    end
  end
end
