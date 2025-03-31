defmodule RoomlyWeb.RoomLive.Show do
  use RoomlyWeb, :live_view

  alias Roomly.Orchestrator

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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
          {:noreply, put_flash(socket, :info, "Room Started!") |> assign(room_activated: true)}

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
         |> assign(room_activated: false)}

      _ ->
        {:noreply, put_flash(socket, :error, "Room is not running")}
    end
  end

  def handle_event("join_room", _params, socket) do
    room = socket.assigns.room
    case join_room(room.id, socket.assigns.current_user.id, room.type) do
      :ok ->
        users = Roomly.Attendance.RoomPresence.get_users(room.id)
        {:noreply, assign(socket, users: users, joined: true)}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to join room")}
    end
  end

  def handle_event("leave_room", _params, socket) do
    room = socket.assigns.room
    case leave_room(room.id, socket.assigns.current_user.id, room.type) do
      :ok ->
        users = Roomly.Attendance.RoomPresence.get_users(room.id)
        {:noreply, assign(socket, users: users, joined: false) |> put_flash(:info, "Left Room")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to leave room")}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    room = Orchestrator.get_room!(id)
    room_activated =
      case Registry.lookup(Roomly.RoomRegistry, room.id) do
        [{_pid, _}] -> true
        [] -> false
      end

    if room_activated do
      Phoenix.PubSub.subscribe(Roomly.PubSub, "room:#{id}")
    end

    presences = Roomly.Attendance.RoomPresence.list("room:#{id}")
    joined = Map.has_key?(presences, socket.assigns.current_user.id)
    users = Roomly.Attendance.RoomPresence.get_users(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, room)
     |> assign(room_activated: room_activated)
     |> assign(users: users)
     |> assign(joined: joined)}
  end

  defp join_room(room_id, user_id, "pomodoro") do
    Roomly.RoomServers.PomoServer.join(room_id, user_id)
  end

  defp leave_room(room_id, user_id, "pomodoro") do
    Roomly.RoomServers.PomoServer.leave(room_id, user_id)
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
