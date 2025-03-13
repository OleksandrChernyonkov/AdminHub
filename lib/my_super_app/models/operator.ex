defmodule MySuperApp.Operator do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false
  @derive {Jason.Encoder, only: [:id, :name]}
  schema "operators" do
    field :name, :string
    has_many :roles, MySuperApp.Role
    has_many :users, MySuperApp.User
    has_many :sites, MySuperApp.Site
    timestamps()
  end

  @doc false
  def changeset(operator, attrs) do
    operator
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name)
  end
end
