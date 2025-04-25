defmodule Roomly.RoomServer do
  alias Roomly.Accounts
  defmacro __using__(_) do
    quote do
      use GenServer

      def join(room_id, user_id) do
        GenServer.call(via_tuple(room_id), {:join_room, user_id})
      end

      def leave(room_id, user_id) do
        GenServer.call(via_tuple(room_id), {:leave_room, user_id})
      end

      def activate_user(room_id, user_id) do
        GenServer.call(via_tuple(room_id), {:activate_user, user_id})
      end

      def deactivate_user(room_id, user_id) do
        GenServer.call(via_tuple(room_id), {:deactivate_user, user_id})
      end

      def get_users(room_id) do
        GenServer.call(via_tuple(room_id), :get_users)
      end

      def handle_call({:join_room, user_id}, {from_pid, _}, %{id: id, users: users} = state) do
        users = Map.put(users, user_id, %{liveview_pid: from_pid, active: Process.alive?(from_pid), joined_at: System.system_time(:second)})
        broadcast_users_diff(id, users)
        {:reply, :ok, %{state | users: users}}
      end

      def handle_call({:leave_room, user_id}, {_from_pid, _}, %{id: id, users: users} = state) do
        users = Map.delete(users, user_id)
        broadcast_users_diff(id, users)
        {:reply, :ok, %{state | users: users}}
      end

      def handle_call({:activate_user, user_id}, {from_pid, _}, %{id: id, users: users} = state) do
        users =
          if Map.has_key?(users, user_id) do
            Map.put(users, user_id, %{liveview_pid: from_pid, active: Process.alive?(from_pid), joined_at: System.system_time(:second)})
          else
            users
          end

        broadcast_users_diff(id, users)
        {:reply, :ok, %{state | users: users}}
      end

      def handle_call({:deactivate_user, user_id}, {from_pid, _}, %{id: id, users: users} = state) do
        users =
          if Map.has_key?(users, user_id) and users[user_id][:liveview_pid] == from_pid  do
            Map.put(users, user_id, %{liveview_pid: from_pid, active: false, joined_at: System.system_time(:second)})
          else
            users
          end

        broadcast_users_diff(id, users)
        {:reply, :ok, %{state | users: users}}
      end

      def handle_call(:get_users, _from, %{users: users} = state) do
        {:reply, Map.filter(users, fn {_k, v} -> v.active end) |> Map.keys() |> Accounts.get_users_by_id(), state}
      end

      defp via_tuple(room_id) do
        {:via, Registry, {Roomly.RoomRegistry, room_id}}
      end

      defp broadcast_users_diff(room_id, users) do
        Phoenix.PubSub.broadcast(Roomly.PubSub, "room:#{room_id}", {:users_diff, %{users: Map.filter(users, fn {_k, v} -> v.active end)}})
      end
    end
  end
end
