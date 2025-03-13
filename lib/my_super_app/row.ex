defmodule MySuperApp.Row do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false

  schema "rows" do
    field :eng_word, :string
    field :ukr_word, :string
    timestamps()
  end

  def changeset(rows, attrs) do
    rows
    |> cast(attrs, [:eng_word, :ukr_word])
    |> validate_required([:eng_word, :ukr_word])
    |> unique_constraint(:eng_word)
  end
end
