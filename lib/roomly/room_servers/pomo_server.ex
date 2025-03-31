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
        status: :idle
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
    # Logger.info("Starting Pomodoro Timer for #{state.id}")
    schedule_timer(config.work_time)
    {:noreply, %{state | status: :work}}
  end

  @impl true

  def handle_info(:switch_timer, %{status: :work, config: config} = state) do
    schedule_timer(config.break_time)
    {:noreply, %{state | status: :break}}
  end

  def handle_info(:switch_timer, %{status: :break, config: config} = state) do
    schedule_timer(config.work_time)
    {:noreply, %{state | status: :work}}
  end

  defp schedule_timer(minutes) do
    Process.send_after(self(), :switch_timer, minutes * 60 * 1000)
  end

  defp via_tuple(room_id) do
    {:via, Registry, {Roomly.RoomRegistry, room_id}}
  end
end
