defmodule MySuperApp.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false
  @derive {Jason.Encoder, only: [:id, :name]}
  schema "permissions" do
    field :name, :string
    has_many :roles, MySuperApp.Role
    timestamps()
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name)
  end
end
