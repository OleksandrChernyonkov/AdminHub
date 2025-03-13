defmodule MySuperApp.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false

  schema "rooms" do
    field :room_number, :integer
    many_to_many :phones, MySuperApp.Phone, join_through: "rooms_phones"
  end

  def changeset(rooms, attrs) do
    rooms
    |> cast(attrs, [:room_number])
    |> validate_required([:room_number])
  end
end
