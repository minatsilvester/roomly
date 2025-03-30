defmodule Roomly.Supervisors.RoomsManager do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_room(%{id: room_id, type: "pomodoro", config: config}) do
    spec = {Roomly.RoomServers.PomoServer, {room_id, config}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_room(room_id) do
    case Registry.lookup(Roomly.RoomRegistry, room_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> {:error, :not_found}
    end
  end
end
