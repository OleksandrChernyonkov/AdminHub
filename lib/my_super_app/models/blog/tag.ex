defmodule MySuperApp.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false
  schema "tags" do
    field :name, :string
    many_to_many :posts, MySuperApp.Blog.Post, join_through: "posts_tags"
    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name)
  end
end
