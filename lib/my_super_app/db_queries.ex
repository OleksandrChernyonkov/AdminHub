defmodule MySuperApp.DbQueries do
  alias MySuperApp.{Repo, Room, Phone}

  import Ecto.Query

  @moduledoc false
  def rooms_with_phones_preload() do
    Room
    |> Repo.all()
    |> Repo.preload(:phones)
  end

  def get_room_by_id(id) do
    Repo.all(
      from room in Room,
        where: room.id == ^id
    )
  end

  def get_phone_by_number(phone_number) do
    from(phone in Phone)
    |> where([phone], phone.phone_number == ^phone_number)
    |> Repo.one()
  end

  def rooms_with_phones() do
    Repo.all(
      from room in Room,
        join: phones in assoc(room, :phones),
        preload: [phones: phones],
        select:
          map(
            room,
            [
              :id,
              :room_number,
              phones: [:id, :phone_number]
            ]
          )
    )
  end

  def rooms_without_phones() do
    Repo.all(
      from room in Room,
        left_join: phone in assoc(room, :phones),
        where: is_nil(phone.id),
        select: %{
          room_number: room.room_number
        }
    )
  end

  def phones_without_rooms() do
    Repo.all(
      from room in Room,
        right_join: phone in assoc(room, :phones),
        where: is_nil(room.id),
        select: %{
          phone_number: phone.phone_number
        }
    )
  end

  def sort(list, :even), do: sort(list, [], :even)
  def sort(list, :odd), do: sort(list, [], :odd)

  def sort([], acc, _), do: Enum.reverse(acc)

  def sort([head | tail], acc, :even) do
    if rem(head, 2) == 0 do
      sort(tail, [head | acc], :even)
    else
      sort(tail, acc, :even)
    end
  end

  def sort([head | tail], acc, :odd) do
    if rem(head, 2) == 1 do
      sort(tail, [head | acc], :odd)
    else
      sort(tail, acc, :odd)
    end
  end
end
