defmodule MySuperAppWeb.SiteController do
  use MySuperAppWeb, :controller
  alias MySuperApp.{CasinosAdmins, Site}

  action_fallback MySuperAppWeb.FallbackController

  def show(conn, %{"id" => id}) do
    case CasinosAdmins.get_site(String.to_integer(id)) do
      %Site{} = site ->
        render(conn, "show.json", site: site)

      nil ->
        conn |> put_status(404) |> json(%{error: "Site not found"})
    end
  end

  def index(conn, %{"operator" => operator_name}) do
    render(conn, "index.json", sites: CasinosAdmins.get_sites_by_operator(operator_name))
  end

  def index(conn, %{"start_date_time" => start_date_time, "end_date_time" => end_date_time}) do
    sites = CasinosAdmins.get_sites_by_period(start_date_time, end_date_time)
    render(conn, :index, sites: sites)
  end

  def index(conn, %{"date" => date_string}) do
    sites = CasinosAdmins.get_sites_by_date(date_string)
    render(conn, :index, sites: sites)
  end

  def index(conn, _params) do
    sites = CasinosAdmins.get_all_sites_for_api()
    render(conn, "index.json", sites: sites)
  end

  def create(conn, %{"site" => site_params}) do
    case CasinosAdmins.create_site(site_params) do
      {:ok, site} ->
        conn |> put_status(201) |> render("show.json", site: site)

      {:error, changeset} ->
        conn |> put_status(422) |> json(%{errors: format_errors(changeset.errors)})
    end
  end

  def update(conn, %{"id" => id, "site" => site_params}) do
    case CasinosAdmins.update_site(id, site_params) do
      {:ok, updated_site} ->
        render(conn, "show.json", site: updated_site)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => "Site not found"})

      {:error, changeset} ->
        conn |> put_status(422) |> json(%{errors: format_errors(changeset.errors)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case CasinosAdmins.delete_site(id) do
      {:ok, _site} ->
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
