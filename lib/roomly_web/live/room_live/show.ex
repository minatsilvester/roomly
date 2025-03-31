defmodule RoomlyWeb.RoomLive.Show do
  use RoomlyWeb, :live_view

  alias Roomly.Orchestrator

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    # {:ok, socket}
    # Orchestrator.get_room!(room_id)
    room_running =
      case Registry.lookup(Roomly.RoomRegistry, room_id) do
        [{_pid, _}] -> true
        [] -> false
      end

    {:ok,
      assign(socket, room_running: room_running)}
  end

  @impl true
  def handle_event("activate_room", _params, socket) do
    case Roomly.Supervisors.RoomsManager.start_room(
      %{
        id: socket.assigns.room.id,
        type: socket.assigns.room.type,
        config: socket.assigns.room.config
      }
    ) do
        {:ok, _pid} ->
          # {:ok, updated_room} = Orchestrator.update_room(socket.assigns.room, %{"status" => "active"})
          {:noreply, put_flash(socket, :info, "Room Started!") |> assign(room_running: true)}

        {:error, {:already_started, _pid}} ->
          {:noreply, put_flash(socket, :error, "Room is already running")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Failed to start room: #{inspect(reason)}")}
    end
  end

  def handle_event("close_room", _params, socket) do
    case Roomly.Supervisors.RoomsManager.stop_room(socket.assigns.room.id) do
      :ok ->
        # {:ok, updated_room} = Orchestrator.update_room(socket.assigns.room, %{"status" => "closed"})
        {:noreply,
         socket
         |> put_flash(:info, "Room stopped!")
         |> assign(:room_running, false)}

      _ ->
        {:noreply, put_flash(socket, :error, "Room is not running")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Orchestrator.get_room!(id))}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
