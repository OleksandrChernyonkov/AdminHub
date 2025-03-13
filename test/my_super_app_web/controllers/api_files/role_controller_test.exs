defmodule MySuperAppWeb.ApiFiles.RoleControllerTest do
  use MySuperAppWeb.ConnCase

  alias MySuperApp.Accounts
  import MySuperApp.{CasinosAdminsFixtures, AccountsFixtures}

  @valid_attrs %{name: "role_name"}
  @updated_attrs %{name: "new_role_name"}
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    role = role_fixture()

    {:ok, user} =
      user_fixture().id
      |> Accounts.update_user(%{role_id: role.id})

    {:ok, conn: conn, role: role, user: user}
  end

  describe "show" do
    test "returns the requested role", %{conn: conn, role: role} do
      conn = get(conn, "/api/roles/#{role.id}")

      assert json_response(conn, 200)["data"]["id"] == role.id
      assert json_response(conn, 200)["data"]["name"] == role.name
    end

    test "returns 404 when the role does not exist", %{conn: conn} do
      conn = get(conn, "/api/roles/#{-1}")

      assert json_response(conn, 404)["error"] == "Role not found"
    end
  end

  describe "index" do
    test "returns roles for a given user", %{conn: conn, user: user, role: role} do
      conn = get(conn, "/api/roles?user_id=#{user.id}")
      assert json_response(conn, 200)["data"]["id"] == role.id
    end

    test "returns role by name", %{conn: conn, role: role} do
      conn = get(conn, "/api/roles?name=#{role.name}")
      assert json_response(conn, 200)["data"]["id"] == role.id
    end

    test "returns all roles", %{conn: conn, role: role} do
      conn = get(conn, "/api/roles/")
      lonely_role = json_response(conn, 200)["data"] |> List.first()

      assert json_response(conn, 200)["data"] |> is_list()
      assert lonely_role["name"] == role.name
    end

    test "returns 404 when the user does not exist", %{conn: conn} do
      conn = get(conn, "/api/roles?user_id=#{-1}")

      assert json_response(conn, 404)["error"] == "User not found"
    end

    test "returns 404 when the role does not exist by name", %{conn: conn} do
      conn = get(conn, "/api/roles?name=#{-1}")

      assert json_response(conn, 404)["error"] == "Role not found"
    end
  end

  describe "create" do
    test "creates a role and returns it", %{conn: conn} do
      conn = post(conn, ~p"/api/roles", role: @valid_attrs)
      response_data = json_response(conn, 201)

      assert conn.status == 201
      assert %{"data" => %{"name" => name}} = response_data
      assert name == @valid_attrs[:name]
    end

    test "fails to create a role and returns validation errors", %{conn: conn} do
      conn = post(conn, ~p"/api/roles", role: @invalid_attrs)
      response_data = json_response(conn, 422)

      assert conn.status == 422
      assert %{"errors" => errors} = response_data
      assert %{"field" => "name", "message" => "can't be blank"} in errors
    end
  end

  describe "update" do
    test "updates a role and returns it", %{conn: conn, role: role} do
      conn = put(conn, ~p"/api/roles/#{role.id}", role: @updated_attrs)
      response_data = json_response(conn, 200)["data"]

      assert response_data["name"] == @updated_attrs.name
    end

    test "returns 404 when the role does not exist", %{conn: conn} do
      conn = put(conn, ~p"/api/roles/#{-1}", role: %{name: "new_role_name"})
      response_data = json_response(conn, 404)

      assert conn.status == 404
      assert response_data["error"] == "Role not found"
    end

    test "returns 422 with errors when role update fails", %{conn: conn, role: role} do
      conn = put(conn, ~p"/api/roles/#{role.id}", role: @invalid_attrs)
      response_data = json_response(conn, 422)

      assert conn.status == 422
      assert %{"errors" => errors} = response_data
      assert %{"field" => "name", "message" => "can't be blank"} in errors
    end
  end

  describe "delete" do
    test "deletes the role and returns no content", %{conn: conn, role: role} do
      conn = delete(conn, ~p"/api/roles/#{role.id}")
      assert conn.status == 204

      conn = get(conn, ~p"/api/roles/#{role.id}")
      assert conn.status == 404
    end

    test "returns 404 when the role does not exist", %{conn: conn} do
      conn = delete(conn, ~p"/api/roles/#{-1}")
      response_data = json_response(conn, 404)

      assert conn.status == 404
      assert response_data["error"] == "Role not found"
    end
  end
end
