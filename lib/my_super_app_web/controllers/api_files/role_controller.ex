defmodule MySuperAppWeb.RoleController do
  use MySuperAppWeb, :controller

  alias MySuperApp.{CasinosAdmins, Accounts, Role, User}

  action_fallback MySuperAppWeb.FallbackController

  def show(conn, %{"id" => id}) do
    case CasinosAdmins.get_role(id) do
      %Role{} = role ->
        render(conn, "show.json", role: role)

      nil ->
        conn |> put_status(404) |> json(%{error: "Role not found"})
    end
  end

  def index(conn, %{"user_id" => user_id}) do
    case Accounts.get_user(user_id) do
      %User{} = user ->
        render(conn, "show.json", role: CasinosAdmins.get_role(user.role_id))

      nil ->
        conn |> put_status(404) |> json(%{error: "User not found"})
    end
  end

  def index(conn, %{"name" => name}) do
    case CasinosAdmins.get_role_by_name(name) do
      %Role{} = role -> render(conn, "show.json", role: role)
      _ -> conn |> put_status(404) |> json(%{error: "Role not found"})
    end
  end

  def index(conn, _params) do
    roles = CasinosAdmins.get_all_roles_for_api()
    render(conn, "index.json", roles: roles)
  end

  def create(conn, %{"role" => role_params}) do
    case CasinosAdmins.create_role(role_params) do
      {:ok, role} ->
        conn |> put_status(201) |> render("show.json", role: role)

      {:error, changeset} ->
        conn |> put_status(422) |> json(%{errors: format_errors(changeset.errors)})
    end
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    case CasinosAdmins.update_role(id, role_params) do
      {:ok, updated_role} ->
        render(conn, "show.json", role: updated_role)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Role not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset.errors)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case CasinosAdmins.delete_role(id) do
      {:ok, _role} ->
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
