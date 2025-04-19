defmodule RoomlyWeb.RoomLive.Components.RoomInfo do
alias Roomly.Accounts
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
            <li class="p-2 bg-gray-200 rounded-md">{user.name}</li>
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
     |> assign(users: Map.keys(users) |> Accounts.get_users_by_id())}
  end

  def update(%{room_activated: room_activated} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> set_room_activated_and_joined(socket.assigns.room, socket.assigns.current_user, room_activated)}
  end

  def update(%{room: room} = assigns, socket) do
    room_activated = Registry.lookup(Roomly.RoomRegistry, room.id) != []

    {:ok,
     socket
     |> assign(assigns)
     |> assign(is_room_admin: assigns.current_user.id == room.user_id)
     |> set_room_activated_and_joined(room, assigns.current_user, room_activated)}
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
         |> set_room_activated_and_joined(socket.assigns.room, socket.assigns.current_user, true)}

      {:error, {:already_started, _pid}} ->
        {:noreply, put_flash(socket, :error, "Room is already running")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start room: #{inspect(reason)}")}
    end
  end

  def handle_event("close_room", _params, socket) do
    Phoenix.PubSub.unsubscribe(Roomly.PubSub, "room:#{socket.assigns.room.id}")
    stop_room_and_acknowledge(socket.assigns.room, socket)
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
        Phoenix.PubSub.unsubscribe(Roomly.PubSub, "room:#{room.id}")
        close_room_if_is_admin(socket.assigns.is_room_admin, room, socket)

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Failed to leave room")}
    end
  end

  defp close_room_if_is_admin(false, _room, socket) do
    {:noreply, assign(socket, joined: false) |> put_flash(:info, "Left Room")}
  end

  defp close_room_if_is_admin(true, room, socket) do
    stop_room_and_acknowledge(room, socket)
  end

  defp set_room_activated_and_joined(socket, _room, _current_user, false) do
    socket
    |> assign(users: [])
    |> assign(room_activated: false)
    |> assign(joined: false)
  end

  defp set_room_activated_and_joined(socket, room, current_user, room_activated) do
    users = get_users(socket.assigns.server, room.id, room_activated)
    joined = Enum.any?(users, &(&1.id == current_user.id))

    socket
    |> assign(users: users)
    |> assign(room_activated: room_activated)
    |> assign(joined: joined)
    |> send_update_to_parent()
  end

  defp send_update_to_parent(socket) do
    send(self(), {:room_activated, true})
    socket
  end


  defp join_room(server, room_id, user_id) do
    server.join(room_id, user_id)
   Phoenix.PubSub.subscribe(Roomly.PubSub, "room:#{room_id}")
  end

  defp leave_room(server, room_id, user_id) do
    server.leave(room_id, user_id)
  end

  defp stop_room_and_acknowledge(room, socket) do
    case Roomly.Supervisors.RoomsManager.stop_room(room.id) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Room stopped!")
         |> assign(room_activated: false)}

      _ ->
        {:noreply, put_flash(socket, :error, "Room is not running")}
    end
  end

  defp get_users(server, room_id, true), do: server.get_users(room_id)
  defp get_users(_server, _room_id, false), do: []
end
