defmodule Roomly.Common.Utils do
  def add_user_id_to_attrs(attrs, user), do: Map.put(attrs, "user_id", user.id)
end
