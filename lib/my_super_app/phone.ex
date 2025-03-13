defmodule MySuperApp.Phone do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false

  schema "phones" do
    field :phone_number, :string
    many_to_many :rooms, MySuperApp.Room, join_through: "rooms_phones"
  end

  def changeset(phones, attrs) do
    phones
    |> cast(attrs, [:phone_number])
    |> validate_required([:phone_number])
  end
end
