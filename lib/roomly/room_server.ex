defmodule Roomly.RoomServer do
  defmacro __using__(_) do
    quote do
      use GenServer

      def join(room_id, user_id) do
        GenServer.call(via_tuple(room_id), {:join_room, user_id})
      end

      def leave(room_id, user_id) do
        GenServer.call(via_tuple(room_id), {:leave_room, user_id})
      end

      def get_users(room_id) do
        GenServer.call(via_tuple(room_id), :get_users)
      end

      def handle_call({:join_room, user_id}, _from, %{id: id, users: users} = state) do
        users = Map.put(users, user_id, %{joined_at: System.system_time(:second)})
        broadcast_users_diff(id, users)
        {:reply, :ok, %{state | users: users}}
      end

      def handle_call({:leave_room, user_id}, _from, %{id: id, users: users} = state) do
        users = Map.delete(users, user_id)
        broadcast_users_diff(id, users)
        {:reply, :ok, %{state | users: users}}
      end

      def handle_call(:get_users, _from, %{users: users} = state) do
        {:reply, Map.keys(users), state}
      end

      defp via_tuple(room_id) do
        {:via, Registry, {Roomly.RoomRegistry, room_id}}
      end

      defp broadcast_users_diff(room_id, users) do
        Phoenix.PubSub.broadcast(Roomly.PubSub, "room:#{room_id}", {:users_diff, %{users: users}})
      end
    end
  end
end
