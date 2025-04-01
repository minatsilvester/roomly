defmodule Roomly.RoomServer do
  alias Roomly.Attendance.RoomPresence

  defmacro __using__(_) do
    quote do
      use GenServer

      def join(room_id, user_id) do
        GenServer.call(via_tuple(room_id), {:join_room, user_id})
      end

      def leave(room_id, user_id) do
        GenServer.call(via_tuple(room_id), {:leave_room, user_id})
      end

      def handle_call({:join_room, user_id}, _from, state) do
        RoomPresence.track_user(state.id, user_id)
        users = RoomPresence.get_users(state.id)
        {:reply, :ok, %{state | users: users}}
      end

      def handle_call({:leave_room, user_id}, _from, state) do
        RoomPresence.untrack_user(state.id, user_id)
        users = Enum.reject(state.users, fn u -> u == user_id end)
        {:reply, :ok, %{state | users: users}}
      end

      defp via_tuple(room_id) do
        {:via, Registry, {Roomly.RoomRegistry, room_id}}
      end
    end
  end
end
