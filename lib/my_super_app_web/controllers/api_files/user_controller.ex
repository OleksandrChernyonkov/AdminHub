defmodule MySuperAppWeb.UserController do
  use MySuperAppWeb, :controller

  alias MySuperApp.{Accounts, User}

  action_fallback MySuperAppWeb.FallbackController

  def show(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      %User{} = user -> render(conn, "show.json", user: user)
      nil -> conn |> put_status(404) |> json(%{error: "User not found"})
    end
  end

  def index(conn, %{"username" => username}) do
    case Accounts.get_user_by_name(username) do
      %User{} = user -> render(conn, "show.json", user: user)
      nil -> conn |> put_status(404) |> json(%{error: "User not found"})
    end
  end

  def index(conn, %{"email" => email}) do
    case Accounts.get_user_by_email(email) do
      %User{} = user -> render(conn, "show.json", user: user)
      nil -> conn |> put_status(:not_found) |> json(%{error: "User not found"})
    end
  end

  def index(conn, %{"role_id" => role_id}) do
    render(conn, "index.json", users: Accounts.get_users_by_role_id_api(role_id))
  end

  def index(conn, _params) do
    render(conn, "index.json", users: Accounts.get_users_api())
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn |> put_status(201) |> render("show.json", user: user)

      {:error, changeset} ->
        conn |> put_status(422) |> json(%{errors: format_errors(changeset.errors)})
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case Accounts.update_user(id, user_params) do
      {:ok, updated_user} ->
        render(conn, "show.json", user: updated_user)

      {:error, changeset} ->
        conn |> put_status(422) |> json(%{errors: format_errors(changeset.errors)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case Accounts.delete_user_by_id(id) do
      {:ok, _user} ->
        send_resp(conn, :no_content, "")

      {:error, reason} ->
        conn
        |> put_status(404)
        |> json(%{error: reason})
    end
  end

  defp format_errors(errors) do
    Enum.map(errors, fn {field, {msg, _opts}} ->
      %{field: Atom.to_string(field), message: msg}
    end)
  end
end
