defmodule MySuperAppWeb.UserControllerTest do
  use MySuperAppWeb.ConnCase

  alias MySuperApp.{CasinosAdmins, Accounts}

  @invalid_attrs %{email: nil, username: nil, password: nil}

  setup do
    create_user()
  end

  describe "get users" do
    test "GET /api/users retrieves a user by id", %{conn: conn, user: user} do
      conn = get(conn, "/api/users/#{user.id}")
      assert json_response(conn, 200)["data"]["id"] == user.id
    end

    test "GET /api/users retrieves a user by username", %{conn: conn, user: user} do
      conn = get(conn, "/api/users", %{"username" => user.username})
      assert json_response(conn, 200)["data"]["id"] == user.id
    end

    test "GET /api/users retrieves a user by email", %{conn: conn, user: user} do
      conn = get(conn, "/api/users", %{"email" => user.email})
      assert json_response(conn, 200)["data"]["id"] == user.id
    end

    test "GET /api/users retrieves users by role_id", %{conn: conn, role: role} do
      conn = get(conn, "/api/users", %{"role_id" => role.id})
      assert json_response(conn, 200)["data"] |> is_list
    end

    test "GET /api/users retrieves all users", %{conn: conn} do
      conn = get(conn, "/api/users")
      assert json_response(conn, 200)["data"] |> is_list
    end
  end

  describe "create user" do
    test "POST /api/users creates a new user with valid data", %{
      conn: conn,
      role: role,
      operator: operator
    } do
      new_attrs = %{
        username: "NewUser",
        email: "new_user@gmail.com",
        password: "NewPassword",
        role_id: role.id,
        operator_id: operator.id
      }

      conn = post(conn, "/api/users", user: new_attrs)
      assert json_response(conn, 201)["data"]["email"] == new_attrs.email
      assert json_response(conn, 201)["data"]["username"] == new_attrs.username
    end

    test "POST /api/users does not create user with invalid data", %{conn: conn} do
      conn = post(conn, "/api/users", user: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{},
             "Expected errors to be present for invalid data"
    end
  end

  describe "update user" do
    test "PUT /api/users/:id updates a user with valid data", %{conn: conn, user: user} do
      update_attrs = %{email: "updated@example.com"}
      conn = put(conn, "/api/users/#{user.id}", user: update_attrs)

      assert json_response(conn, 200)["data"]["email"] == "updated@example.com"
    end

    test "PUT /api/users/:id does not update user with invalid data", %{conn: conn, user: user} do
      conn = put(conn, "/api/users/#{user.id}", user: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{},
             "Expected errors to be present for invalid data"
    end
  end

  describe "delete user" do
    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/api/users/#{user.id}")
      assert response(conn, 204)
      conn = get(conn, ~p"/api/users/#{user.id}")

      assert conn.status == 404
      assert json_response(conn, 404)["error"] == "User not found"
    end
  end

  def create_user() do
    {:ok, role} = CasinosAdmins.create_role(%{name: "admin"})
    {:ok, operator} = CasinosAdmins.create_operator(%{name: "test_operator"})

    {:ok, user} =
      Accounts.register_user(%{
        username: "TestName",
        email: "TestName@gmail.com",
        password: "RandomPassword",
        role_id: role.id,
        operator_id: operator.id
      })

    %{role: role, operator: operator, user: user}
  end
end
