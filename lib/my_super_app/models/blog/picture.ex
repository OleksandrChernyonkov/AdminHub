defmodule MySuperApp.Picture do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false
  @derive {Jason.Encoder, only: [:id, :file_name, :path, :upload_at, :post_id]}
  schema "pictures" do
    field :file_name, :string
    field :path, :string
    field :upload_at, :utc_datetime
    belongs_to :post, MySuperApp.Blog.Post
    timestamps()
  end

  @doc false
  def changeset(picture, attrs) do
    picture
    |> cast(attrs, [:file_name, :path, :upload_at, :post_id])
    |> validate_required([:file_name, :path])
    |> unique_constraint(:file_name)
    |> unique_constraint(:path)
  end
end
