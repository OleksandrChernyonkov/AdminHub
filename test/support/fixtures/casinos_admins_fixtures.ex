defmodule MySuperApp.CasinosAdminsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MySuperApp.CasinosAdmins` context.
  """

  @doc """
  Generate a role.
  """
  def role_fixture(attrs \\ %{}) do
    {:ok, role} =
      attrs
      |> Enum.into(%{
        name: "some_name",
        operator_id: MySuperApp.Repo.insert!(%MySuperApp.Operator{name: "some_operator"}).id,
        permission_id: MySuperApp.Repo.insert!(%MySuperApp.Permission{name: "some_permission"}).id
      })
      |> MySuperApp.CasinosAdmins.create_role()

    role
    |> MySuperApp.Repo.preload([:operator, :permission])
  end

  @doc """
  Generate a permission.
  """
  def permission_fixture(attrs \\ %{}) do
    {:ok, permission} =
      attrs
      |> Enum.into(%{
        name: "some_name"
      })
      |> MySuperApp.CasinosAdmins.create_permission()

    permission
    |> MySuperApp.Repo.preload([:roles])
  end

  @doc """
  Generate a site.
  """
  def site_fixture(attrs \\ %{}) do
    {:ok, site} =
      attrs
      |> Enum.into(%{
        brand: "some_brand",
        status: "ACTIVE",
        operator_id: MySuperApp.Repo.insert!(%MySuperApp.Operator{name: "second_operator"}).id
      })
      |> MySuperApp.CasinosAdmins.create_site()

    site
    |> MySuperApp.Repo.preload([:operator])
  end

  @doc """
  Generate an operator.
  """
  def operator_fixture(attrs \\ %{}) do
    {:ok, operator} =
      attrs
      |> Enum.into(%{
        name: "some_operator"
      })
      |> MySuperApp.CasinosAdmins.create_operator()

    operator
  end
end
