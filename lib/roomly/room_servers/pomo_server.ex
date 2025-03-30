defmodule Roomly.RoomServers.PomoServer do
  use GenServer
  alias Roomly.Attendance.RoomPresence

  def start_link({room_id, config}) do
    GenServer.start_link(
      __MODULE__,
      {room_id, config},
      name: via_tuple(room_id)
    )
  end

  @impl true
  def init({room_id, config}) do
    {:ok,
      %{
        id: room_id,
        config: config,
        rounds: 0,
        users: [],
        status: :not_started
      }
    }
  end

  @impl true
  def handle_call({:join_room, user_id}, _from, state) do
    RoomPresence.track_user(state.id, user_id)
    users = RoomPresence.get_users(state.id)
    {:reply, :ok, %{state | users: users}}
  end

  def join(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:join_room, user_id})
  end

  defp via_tuple(room_id) do
    {:via, Registry, {Roomly.RoomRegistry, room_id}}
  end
end
