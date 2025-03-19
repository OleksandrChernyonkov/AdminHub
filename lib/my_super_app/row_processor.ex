defmodule MySuperApp.RowProcessor do
  alias MySuperApp.{Repo, Row}
  import Ecto.Query

  @moduledoc false

  def create_row(attrs \\ %{}) do
    %Row{}
    |> Row.changeset(attrs)
    |> Repo.insert()
  end

  def get_row!(id) do
    Repo.get(Row, id)
  end

  def get_list() do
    query = from(r in Row, order_by: [asc: r.id], select: r)

    rows =
      Repo.all(query)
      |> Enum.map(&Map.from_struct/1)

    if rows == [] do
      []
    else
      rows
    end
  end

  def get_list_by_id_range(from_id, to_id) do
    from_id = if from_id == "", do: get_min_id(get_list()), else: from_id
    to_id = if to_id == "", do: get_max_id(get_list()), else: to_id

    query =
      from(r in Row, where: r.id >= ^from_id and r.id <= ^to_id, order_by: [asc: r.id], select: r)

    rows =
      Repo.all(query)
      |> Enum.map(&Map.from_struct/1)

    if rows == [] do
      []
    else
      rows
    end
  end

  def get_random_row([]) do
    %{}
  end

  def get_random_row(rows) do
    Enum.random(rows)
  end

  def get_filter_form([]) do
    %{
      "from_id" => 0,
      "to_id" => 0
    }
  end

  def get_filter_form(rows) do
    %{
      "from_id" => get_min_id(rows),
      "to_id" => get_max_id(rows)
    }
  end

  def process_rows(rows) do
    rows
    |> String.split("\n")
    |> Enum.each(fn row -> process_row(row) end)
  end

  def change_type("ENG/UKR") do
    "UKR/ENG"
  end

  def change_type("UKR/ENG") do
    "ENG/UKR"
  end

  def get_translation("ENG/UKR", row) do
    row[:ukr_word]
  end

  def get_translation("UKR/ENG", row) do
    row[:eng_word]
  end

  def get_original_word("ENG/UKR", row) do
    row[:eng_word]
  end

  def get_original_word("UKR/ENG", row) do
    row[:ukr_word]
  end

  def get_min_id(list) do
    list
    |> Enum.map(fn row -> row[:id] end)
    |> Enum.min()
  end

  def get_max_id(list) do
    list
    |> Enum.map(fn row -> row[:id] end)
    |> Enum.max()
  end

  def remove_row_from_rows(rows, row_id) do
    Enum.filter(rows, fn row -> row.id != row_id end)
  end

  defp process_row(row) do
    row_parts = String.split(row, " - ", parts: 2)

    case row_parts do
      [eng_word, ukr_word] ->
        eng_word = String.trim(eng_word)
        ukr_word = String.trim(ukr_word)

        create_row(%{eng_word: eng_word, ukr_word: ukr_word})

      _ ->
        IO.puts("Error. Incorrect row format: #{row}")
    end
  end
end
