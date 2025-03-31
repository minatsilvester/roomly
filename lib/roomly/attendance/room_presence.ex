defmodule Roomly.Attendance.RoomPresence do
  use Phoenix.Presence,
    otp_app: :roomly,
    pubsub_server: Roomly.PubSub

  def track_room(room_id) do
    track(self(), "room:#{room_id}", "system", %{active: true})
  end

  def track_user(room_id, user_id) do
    track(self(), "room:#{room_id}", user_id, %{joined_at: System.system_time(:second)})
  end

  def untrack_user(room_id, user_id) do
    untrack(self(), "room:#{room_id}", user_id)
  end

  def get_users(room_id) do
    list("room:#{room_id}")
    |> Map.keys()
  end
end
