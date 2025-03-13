defmodule MySuperApp.CasinosAdminsTest do
  use MySuperApp.DataCase

  alias MySuperApp.CasinosAdmins
  alias MySuperApp.{Operator, Role, Site, Permission}

  @valid_role_attrs %{
    name: "some_name"
  }
  @valid_site_attrs %{
    brand: "some_brand",
    status: "ACTIVE",
    operator_id: nil
  }
  @valid_operator_attrs %{
    name: "some_operator"
  }

  @valid_permission_attrs %{
    name: "some_permission"
  }

  @update_role_attrs %{name: "Updated Role"}

  @invalid_attrs %{name: ""}

  describe "create_operator" do
    test "creates an operator with valid attributes" do
      assert {:ok, %Operator{name: name}} = CasinosAdmins.create_operator(@valid_operator_attrs)
      assert name == @valid_operator_attrs.name
    end

    test "returns error changeset with invalid attributes" do
      assert {:error, _changeset} = CasinosAdmins.create_operator(@invalid_attrs)
    end
  end

  describe "create_permission" do
    test "creates a permission with valid attributes" do
      assert {:ok, %Permission{name: name}} =
               CasinosAdmins.create_permission(@valid_permission_attrs)

      assert name == @valid_permission_attrs.name
    end

    test "returns error changeset with invalid attributes" do
      assert {:error, _changeset} = CasinosAdmins.create_permission(@invalid_attrs)
    end
  end

  describe "create_site" do
    test "creates a site with valid attributes" do
      assert {:ok, %Site{brand: brand}} = CasinosAdmins.create_site(@valid_site_attrs)
      assert brand == @valid_site_attrs.brand
    end

    test "returns error changeset with invalid attributes" do
      assert {:error, _changeset} = CasinosAdmins.create_site(@invalid_attrs)
    end
  end

  describe "create_role" do
    test "creates a role with valid attributes" do
      assert {:ok, %Role{name: name}} = CasinosAdmins.create_role(@valid_role_attrs)
      assert name == @valid_role_attrs.name
    end

    test "returns error changeset with invalid attributes" do
      assert {:error, _changeset} = CasinosAdmins.create_role(@invalid_attrs)
    end
  end

  describe "get_role" do
    test "retrieves a role by id" do
      {:ok, role} = CasinosAdmins.create_role(@valid_role_attrs)
      assert CasinosAdmins.get_role(role.id) == role
    end

    test "returns nil if role does not exist" do
      assert CasinosAdmins.get_role(-1) == nil
    end
  end

  describe "get_site" do
    test "retrieves a site by id" do
      {:ok, operator} = CasinosAdmins.create_operator(@valid_operator_attrs)

      {:ok, site} =
        CasinosAdmins.create_site(Map.put(@valid_site_attrs, :operator_id, operator.id))

      assert CasinosAdmins.get_site(site.id) == site
    end

    test "returns nil if site does not exist" do
      assert CasinosAdmins.get_site(-1) == nil
    end
  end

  describe "get_sites_by_operator" do
    test "returns sites associated with an operator" do
      {:ok, operator} = CasinosAdmins.create_operator(@valid_operator_attrs)

      {:ok, _site} =
        CasinosAdmins.create_site(Map.put(@valid_site_attrs, :operator_id, operator.id))

      assert length(CasinosAdmins.get_sites_by_operator(operator.name)) == 1
    end
  end

  describe "get_operator" do
    test "retrieves an operator by id" do
      {:ok, operator} = CasinosAdmins.create_operator(@valid_operator_attrs)
      assert CasinosAdmins.get_operator(operator.id) == operator
    end

    test "get nil if operator does not exist" do
      assert CasinosAdmins.get_operator(-1) == nil
    end
  end

  describe "get_all_sites" do
    test "returns all sites" do
      {:ok, operator} = CasinosAdmins.create_operator(@valid_operator_attrs)

      {:ok, site} =
        CasinosAdmins.create_site(Map.put(@valid_site_attrs, :operator_id, operator.id))

      assert length(CasinosAdmins.get_all_sites()) > 0

      assert Enum.any?(CasinosAdmins.get_all_sites(), fn s ->
               s.id == site.id and s.brand == site.brand
             end)
    end
  end

  describe "get_all_roles" do
    test "returns all roles" do
      {:ok, role} = CasinosAdmins.create_role(@valid_role_attrs)
      assert length(CasinosAdmins.get_all_roles()) > 0

      assert Enum.any?(CasinosAdmins.get_all_roles(), fn r ->
               r.id == role.id and r.name == role.name
             end)
    end
  end

  describe "get_all_operators" do
    test "returns all operators" do
      {:ok, operator} = CasinosAdmins.create_operator(@valid_operator_attrs)
      assert length(CasinosAdmins.get_all_operators()) > 0

      assert Enum.any?(CasinosAdmins.get_all_operators(), fn o ->
               o.id == operator.id and o.name == operator.name
             end)
    end
  end

  describe "update_role" do
    test "updates a role with valid attributes" do
      {:ok, role} = CasinosAdmins.create_role(@valid_role_attrs)
      assert {:ok, %Role{} = role} = CasinosAdmins.update_role(role.id, @update_role_attrs)
      assert role.name == @update_role_attrs.name
    end

    test "returns error if role does not exist" do
      assert {:error, :not_found} = CasinosAdmins.update_role(-1, @update_role_attrs)
    end
  end

  describe "delete_role" do
    test "deletes an existing role" do
      {:ok, role} = CasinosAdmins.create_role(@valid_role_attrs)
      assert {:ok, %Role{}} = CasinosAdmins.delete_role(role.id)
      assert CasinosAdmins.get_role(role.id) == nil
    end

    test "returns error if role does not exist" do
      assert {:error, "Role not found"} = CasinosAdmins.delete_role(-1)
    end
  end

  describe "delete_site" do
    test "deletes an existing site" do
      {:ok, site} = CasinosAdmins.create_site(@valid_site_attrs)

      assert {:ok, %Site{}} = CasinosAdmins.delete_site(site.id)
      assert CasinosAdmins.get_site(site.id) == nil
    end

    test "returns error if site does not exist" do
      assert {:error, "Site not found"} = CasinosAdmins.delete_site(-1)
    end
  end
end
