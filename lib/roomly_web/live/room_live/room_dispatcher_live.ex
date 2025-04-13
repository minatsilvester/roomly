defmodule RoomlyWeb.RoomLive.RoomDispatcherLive do
  use RoomlyWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false, temporary_assigns: []}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    room = Roomly.Orchestrator.get_room!(id)

    {:noreply, push_navigate(socket, to: specific_room_url(room.type, id))}
  end

  defp specific_room_url("pomodoro", id), do: ~p"/rooms/pomo_room/#{id}"
  defp specific_room_url("chat", id), do: ~p"/rooms/chat_room/#{id}"
end
