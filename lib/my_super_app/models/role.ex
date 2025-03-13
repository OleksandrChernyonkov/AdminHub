defmodule MySuperApp.Role do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false
  schema "roles" do
    field :name, :string
    belongs_to :operator, MySuperApp.Operator
    belongs_to :permission, MySuperApp.Permission
    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :operator_id, :permission_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 50)
    |> unique_constraint(:name)
  end
end
