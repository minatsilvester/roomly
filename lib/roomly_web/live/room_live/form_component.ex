defmodule RoomlyWeb.RoomLive.FormComponent do
  use RoomlyWeb, :live_component

  alias Roomly.Orchestrator

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage room records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="room-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          options={[{"Pomodoro", "pomodoro"}, {"Music", "music"}, {"Chat", "chat"}]}
          phx-change="update_type"
        />

        <%= if @selected_type == "pomodoro" do %>
          <.inputs_for :let={fp} field={@form[:config]}>
            <.input field={fp[:work_duration]} type="text" label="Work Duration (min)" />
            <.input field={fp[:break_duration]} type="text" label="break Duration (min)" />
            <.input field={fp[:rounds]} type="text" label="Rounds" />
          </.inputs_for>
          <%!-- <.input field={@form[:config][:break_duration]} type="text" placeholder="Break Duration (min)"/>
          <.input field={@form[:config][:rounds]} type="text" placeholder="No Of Rounds"/> --%>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Room</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{room: room} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Orchestrator.change_room(room))
     end)}
  end

  @impl true
  def handle_event("validate", %{"room" => room_params}, socket) do
    changeset = Orchestrator.change_room(socket.assigns.room, room_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"room" => room_params}, socket) do
    save_room(socket, socket.assigns.action, room_params)
  end

  def handle_event("update_type", %{"room" => %{"type" => type}}, socket) do
    {:noreply, assign(socket, selected_type: type)}
  end

  defp save_room(socket, :edit, room_params) do
    case Orchestrator.update_room(socket.assigns.room, room_params) do
      {:ok, room} ->
        notify_parent({:saved, room})

        {:noreply,
         socket
         |> put_flash(:info, "Room updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_room(socket, :new, room_params) do
    case Orchestrator.create_room(room_params, socket.assigns.current_user) do
      {:ok, room} ->
        notify_parent({:saved, room})

        {:noreply,
         socket
         |> put_flash(:info, "Room created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
