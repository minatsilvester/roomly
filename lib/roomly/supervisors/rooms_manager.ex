defmodule Roomly.Supervisors.RoomsManager do
  use DynamicSupervisor
  alias Phoenix.PubSub

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_room(%{id: room_id, type: "pomodoro", config: config}) do
    spec = {Roomly.RoomServers.PomoServer, {room_id, config}}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        PubSub.broadcast(Roomly.PubSub, "room_activation:#{room_id}", {:room_activation, true})
        {:ok, pid}

      error ->
        error
    end
  end

  def stop_room(room_id) do
    case Registry.lookup(Roomly.RoomRegistry, room_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        PubSub.broadcast(Roomly.PubSub, "room_activation:#{room_id}", {:room_activation, false})

      [] ->
        {:error, :not_found}
    end
  end
end
