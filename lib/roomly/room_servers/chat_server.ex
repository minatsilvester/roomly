defmodule Roomly.RoomServers.ChatServer do
  use Roomly.RoomServer
  alias Phoenix.PubSub

  def start_link(room_id) do
    GenServer.start_link(__MODULE__, room_id, name: via_tuple(room_id))
  end

  @impl true
  def init(room_id) do
    {:ok,
     %{
        id: room_id,
        users: [],
        messages: []
     }}
  end

  def get_messages(room_id) do
    GenServer.call(via_tuple(room_id), :get_messages)
  end

  def append_message(room_id, message) do
    GenServer.cast(via_tuple(room_id), {:append_message, message})
  end

  def handle_call(:get_messages, _from, %{messages: messages} = state) do
    {:reply, messages, state}
  end

  @impl true
  def handle_cast({:append_message, message}, state) do
    new_messages = state.messages ++ [message]

    PubSub.broadcast(Roomly.Pubsub, "room:#{state.id}", {:new_message, message})

    {:noreply, %{state | messages: new_messages}}
  end
end
