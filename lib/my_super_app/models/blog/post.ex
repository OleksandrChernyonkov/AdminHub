defmodule MySuperApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset
  @moduledoc false

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published_at, :utc_datetime
    belongs_to :user, MySuperApp.User
    many_to_many :tags, MySuperApp.Tag, join_through: "posts_tags"
    has_one :picture, MySuperApp.Picture

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :user_id, :published_at])
    |> validate_required([:title, :body])
  end
end
