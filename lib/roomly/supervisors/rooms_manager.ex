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
    # spec = {Roomly.RoomServers.PomoServer, {room_id, config}}
    start_child(
      {Roomly.RoomServers.PomoServer, {room_id, config}},
      room_id
    )
  end

  def start_room(%{id: room_id, type: "chat", config: _config}) do
    # spec = {Roomly.RoomServers.ChatServer, room_id}
    start_child(
      {Roomly.RoomServers.ChatServer, room_id},
      room_id
    )
  end

  def stop_room(room_id) do
    case Registry.lookup(Roomly.RoomRegistry, room_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        PubSub.broadcast(Roomly.PubSub, "room:#{room_id}", {:room_activation, false})

      [] ->
        {:error, :not_found}
    end
  end

  defp start_child(spec, room_id) do
    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        PubSub.broadcast(Roomly.PubSub, "room:#{room_id}", {:room_activation, true})
        {:ok, pid}

      error ->
        error
    end
  end
end
