defmodule MySuperAppWeb.PictureController do
  use MySuperAppWeb, :controller

  alias MySuperApp.{Pictures, Repo, Blog, Picture}

  action_fallback MySuperAppWeb.FallbackController

  def index(conn, %{"picture_id" => id}) do
    case Pictures.get_picture(id) do
      %Picture{} = picture ->
        render(conn, :show_path, picture: picture)

      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Picture not found"})
    end
  end

  def index(conn, %{"start_date_time" => start_date_time, "end_date_time" => end_date_time}) do
    pictures = Pictures.get_pictures_by_period(start_date_time, end_date_time)
    render(conn, "index.json", pictures: pictures)
  end

  def index(conn, %{"start_date" => start_date, "end_date" => end_date}) do
    {:ok, start_date_time, _} = DateTime.from_iso8601("#{start_date}T00:00:00Z")
    {:ok, end_date_time, _} = DateTime.from_iso8601("#{end_date}T23:59:59Z")

    pictures = Pictures.get_pictures_by_period(start_date_time, end_date_time)
    render(conn, "index.json", pictures: pictures)
  end

  def index(conn, %{"post_id" => post_id}) do
    pictures = Pictures.get_pictures_by_post_id(post_id)
    render(conn, :index, pictures: pictures)
  end

  def index(conn, %{"author_name" => author_name}) do
    pictures = Pictures.get_pictures_by_author_name(author_name)
    render(conn, :index, pictures: pictures)
  end

  def index(conn, %{"author_email" => author_email}) do
    pictures = Pictures.get_pictures_by_author_email(author_email)
    render(conn, :index, pictures: pictures)
  end

  def index(conn, params) do
    sort_order = Map.get(params, "sort_order", "desc") |> String.to_atom()

    pictures = Pictures.list_pictures(sort_order)
    render(conn, :index, pictures: pictures)
  end

  def update(conn, %{"post_id" => post_id, "url" => url}) do
    case Blog.replace_picture(post_id, url) do
      {:ok, picture} -> render(conn, :show, picture: picture)
      {:error, changeset} -> conn |> put_status(400) |> json(%{error: changeset})
    end
  end

  def update(conn, %{"id" => nil, "url" => _url}) do
    conn
    |> put_status(422)
    |> json(%{errors: [%{field: "url", message: "can`t be blank"}]})
  end

  def update(conn, %{"id" => id, "url" => url}) do
    picture = Repo.get!(Picture, id)

    changeset = Picture.changeset(picture, %{path: url, upload_at: NaiveDateTime.utc_now()})

    case Repo.update(changeset) do
      {:ok, updated_picture} ->
        json(conn, %{data: updated_picture})

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> json(%{errors: format_errors(changeset.errors)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case Pictures.get_picture(id) do
      %Picture{} = picture ->
        case Pictures.delete_picture(picture) do
          {:ok, _picture} ->
            conn
            |> put_status(:no_content)
            |> json(%{message: "Picture deleted successfully"})

          {:error, _changeset} ->
            conn
            |> put_status(500)
            |> json(%{error: "Failed to delete picture"})
        end

      nil ->
        conn
        |> put_status(404)
        |> json(%{error: "Picture not found"})
    end
  end

  defp format_errors(errors) do
    Enum.map(errors, fn {field, {msg, _opts}} ->
      %{field: Atom.to_string(field), message: msg}
    end)
  end
end
