defmodule Roomly.RoomServers.PomoServer do
  use GenServer
  alias Roomly.Attendance.RoomPresence
  alias Phoenix.PubSub

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
        status: :idle,
        remaining_time: nil
      }
    }
  end

  def join(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:join_room, user_id})
  end

  def leave(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:leave_room, user_id})
  end

  def get_state(room_id) do
    GenServer.call(via_tuple(room_id), :get_state)
  end

  # Start Timer
  def start_timer(room_id) do
    GenServer.cast(via_tuple(room_id), :start_timer)
  end

  @impl true
  def handle_call({:join_room, user_id}, _from, state) do
    RoomPresence.track_user(state.id, user_id)
    users = RoomPresence.get_users(state.id)
    {:reply, :ok, %{state | users: users}}
  end

  @impl true
  def handle_call({:leave_room, user_id}, _from, state) do
    RoomPresence.untrack_user(state.id, user_id)
    users = Enum.reject(state.users, fn u -> u == user_id end)
    {:reply, :ok, %{state | users: users}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:start_timer, %{status: :idle, config: config} = state) do
    remaining_time = config.work_duration * 60
    schedule_tick()
    broadcast_update(state.id, remaining_time, :work)

    {:noreply, %{state | status: :work, remaining_time: remaining_time}}
  end

  @impl true
  def handle_info(:tick, %{remaining_time: time} = state) when time > 0 do
    schedule_tick()
    broadcast_update(state.id, time - 1, state.status)

    {:noreply, %{state | remaining_time: time - 1}}
  end

  def handle_info(:tick, %{status: :work, config: config} = state) do
    remaining_time = config.break_duration * 60
    schedule_tick()
    broadcast_update(state.id, remaining_time, :break)

    {:noreply, %{state | status: :break, remaining_time: remaining_time}}
  end

  def handle_info(:tick, %{status: :break, config: config} = state) do
    remaining_time = config.work_duration * 60
    schedule_tick()
    broadcast_update(state.id, remaining_time, :work)

    {:noreply, %{state | status: :work, remaining_time: remaining_time}}
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, 1000)
  end

  defp broadcast_update(room_id, time, status) do
    PubSub.broadcast(Roomly.PubSub, "room:#{room_id}", {:timer_update, time, status})
  end

  defp via_tuple(room_id) do
    {:via, Registry, {Roomly.RoomRegistry, room_id}}
  end
end
