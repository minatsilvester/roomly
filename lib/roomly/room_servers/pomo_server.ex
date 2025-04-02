defmodule Roomly.RoomServers.PomoServer do
  use Roomly.RoomServer
  alias Roomly.Rooms.Pomodoro
  alias Phoenix.PubSub

  def start_link({room_id, config}) do
    GenServer.start_link(__MODULE__, {room_id, config}, name: via_tuple(room_id))
  end

  @impl true
  def init({room_id, config}) do
    pomo = Pomodoro.new(config)

    {:ok,
     %{
       id: room_id,
       pomo: pomo,
       users: []
     }}
  end

  def start_timer(room_id) do
    GenServer.cast(via_tuple(room_id), :start_timer)
  end

  def stop_timer(room_id, config) do
    GenServer.cast(via_tuple(room_id), {:stop_timer, config})
  end

  @impl true
  def handle_cast(:start_timer, %{pomo: pomo} = state) do
    new_pomo = Pomodoro.start_timer(pomo)
    schedule_tick()
    broadcast_update(state.id, new_pomo.remaining_time, :work)

    {:noreply, %{state | pomo: new_pomo}}
  end

  def handle_cast({:stop_timer, config}, state) do
    new_pomo = Pomodoro.new(config)
    broadcast_update(state.id, new_pomo.remaining_time, :work)
    {:noreply, %{state | pomo: new_pomo}}
  end

  @impl true
  def handle_info(:tick, %{pomo: pomo} = state) do
    new_pomo = Pomodoro.handle_tick(pomo)

    if new_pomo.status == :completed do
      broadcast_update(state.id, new_pomo.remaining_time, :completed)
    else
      schedule_tick()
      broadcast_update(state.id, new_pomo.remaining_time, new_pomo.status)
    end

    {:noreply, %{state | pomo: new_pomo}}
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, 1000)
  end

  defp broadcast_update(room_id, time, status) do
    PubSub.broadcast(Roomly.PubSub, "room:#{room_id}", {:timer_update, time, status})
  end
end
