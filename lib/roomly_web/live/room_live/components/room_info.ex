defmodule RoomlyWeb.RoomLive.Components.RoomInfo do
  use RoomlyWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex m-8">
      <div class="w-4/5">
        <div class="flex justify-between my-10">
          <div>
            <div class="text-2xl font-bold">{@room.name}</div>
            <div>{@room.description}</div>
          </div>

          <div class="mr-8 mt-2">
            <%= if @is_room_admin do %>
              <%= if !@room_activated do %>
                <.button phx-click="activate_room" phx-target={@myself}>Activate room</.button>
              <% else %>
                <.button phx-click="close_room" phx-target={@myself}>Close room</.button>
              <% end %>
            <% end %>
          </div>
        </div>

        <%= if !@room_activated and !@is_room_admin do %>
          <div class="flex items-center justify-center bg-gray-300 bg-opacity-50 h-full rounded-xl">
            <div class="my-32">Wait till the admin activates the room</div>
          </div>
        <% end %>

        <%= if !@room_activated and @is_room_admin do %>
          <div class="flex items-center justify-center bg-gray-300 bg-opacity-50 h-full rounded-xl">
            <div class="my-32">Activate the room to join</div>
          </div>
        <% end %>

        <%= if @room_activated and !@joined do %>
          <div class="flex items-center justify-center bg-gray-300 bg-opacity-50 h-full rounded-xl">
            <.button phx-click="join_room" phx-target={@myself} class="my-32">Join room</.button>
          </div>
        <% end %>

        <%= if @joined do %>
          <div class="grid">
            <div class="mr-8 justify-self-end">
              <.button phx-click="leave_room" phx-target={@myself}>Leave room</.button>
            </div>
            <div class="m-4">
              {render_slot(@inner_block)}
            </div>
          </div>
        <% end %>
      </div>

      <div class="w-1/5 ml-8 mt-12 bg-white p-4 border-l">
        <h2 class="text-xl font-semibold mb-3">Users in Room</h2>
        <ul class="space-y-2">
          <%= for user <- @users do %>
            <li class="p-2 bg-gray-200 rounded-md">{user}</li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def update(%{payload: %{users: users}} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(users: Map.keys(users))}
  end

  def update(%{room_activated: room_activated} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> activate_and_join(socket.assigns.room, socket.assigns.current_user, room_activated)}
  end

  def update(%{room: room} = assigns, socket) do
    Phoenix.PubSub.subscribe(Roomly.PubSub, "room:#{room.id}")

    room_activated = Registry.lookup(Roomly.RoomRegistry, room.id) != []

    {:ok,
     socket
     |> assign(assigns)
     |> assign(is_room_admin: assigns.current_user.id == room.user_id)
     |> activate_and_join(room, assigns.current_user, room_activated)}
  end

  def handle_event("activate_room", _params, socket) do
    case Roomly.Supervisors.RoomsManager.start_room(%{
           id: socket.assigns.room.id,
           type: socket.assigns.room.type,
           config: socket.assigns.room.config
         }) do
      {:ok, _pid} ->
        join_room(socket.assigns.server, socket.assigns.room.id, socket.assigns.current_user.id)

        {:noreply,
         put_flash(socket, :info, "Room Started!")
         |> activate_and_join(socket.assigns.room, socket.assigns.current_user, true)}

      {:error, {:already_started, _pid}} ->
        {:noreply, put_flash(socket, :error, "Room is already running")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start room: #{inspect(reason)}")}
    end
  end

  def handle_event("close_room", _params, socket) do
    case Roomly.Supervisors.RoomsManager.stop_room(socket.assigns.room.id) do
      :ok ->
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

    case join_room(socket.assigns.server, room.id, socket.assigns.current_user.id) do
      :ok ->
        {:noreply, assign(socket, joined: true)}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to join room")}
    end
  end

  def handle_event("leave_room", _params, socket) do
    room = socket.assigns.room

    case leave_room(socket.assigns.server, room.id, socket.assigns.current_user.id) do
      :ok ->
        {:noreply, assign(socket, joined: false) |> put_flash(:info, "Left Room")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to leave room")}
    end
  end

  defp activate_and_join(socket, room, current_user, room_activated) do
    users = get_users(socket.assigns.server, room.id, room_activated)
    joined = Enum.any?(users, &(&1 == current_user.id))

    socket
    |> assign(users: users)
    |> assign(room_activated: room_activated)
    |> assign(joined: joined)
  end

  defp join_room(server, room_id, user_id) do
    server.join(room_id, user_id)
  end

  defp leave_room(server, room_id, user_id) do
    server.leave(room_id, user_id)
  end

  defp get_users(server, room_id, true), do: server.get_users(room_id)
  defp get_users(_server, _room_id, false), do: []
end
