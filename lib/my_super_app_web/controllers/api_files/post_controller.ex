defmodule MySuperAppWeb.PostController do
  use MySuperAppWeb, :controller

  alias MySuperApp.Blog
  alias MySuperApp.Blog.Post

  action_fallback MySuperAppWeb.FallbackController

  def index(conn, %{"start_date_time" => start_date_time, "end_date_time" => end_date_time}) do
    posts = Blog.get_posts_by_period(start_date_time, end_date_time)
    render(conn, :index, posts: posts)
  end

  def index(conn, %{"date" => date}) do
    posts = Blog.get_posts_by_date(date)
    render(conn, :index, posts: posts)
  end

  def index(conn, %{"tags" => tags_names}) do
    tags_names = String.split(tags_names, ",")
    posts = Blog.get_posts_by_tags(tags_names)
    render(conn, :index, posts: posts)
  end

  def index(conn, _params) do
    posts = Blog.list_posts()
    render(conn, :index, posts: posts)
  end

  def create(conn, %{"post" => post_params}) do
    tags_names = post_params["tags"] |> Enum.map(fn tag -> tag["name"] <> " " end)
    tags = Enum.map(tags_names, fn tag_name -> Blog.get_tag_by_name(tag_name) end)
    post_params = Map.put(post_params, "tags", tags)

    with {:ok, %Post{} = post} <- Blog.create_post(post_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/posts/#{post}")
      |> render(:show, post: post)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    render(conn, :show, post: post)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    with {:ok, %Post{} = post} <- Blog.update_post(String.to_integer(id), post_params) do
      render(conn, :show, post: post)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Blog.get_post!(id)

    with {:ok, %Post{}} <- Blog.delete_post(post) do
      send_resp(conn, :no_content, "")
    end
  end
end
