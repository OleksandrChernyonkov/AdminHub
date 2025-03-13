defmodule MySuperApp.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false
  alias MySuperApp.{Repo, Tag, Blog.Post, User, Pictures, Picture}
  alias MySuperApp.Blog.Post

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    Repo.all(Post)
    |> Repo.preload([:tags, :user, :picture])
  end

  def replace_picture(post_id, url) do
    id = String.to_integer(post_id)
    picture = Pictures.get_pictures_by_post_id(id) |> hd()

    case picture do
      nil ->
        {:error, "Picture not found"}

      picture ->
        picture
        |> Picture.changeset(%{path: url})
        |> Repo.update()
    end
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """

  def get_post(id) do
    Repo.get(Post, id)
    |> Repo.preload([:user, :tags, :picture])
  end

  def get_post!(id) do
    Repo.get!(Post, id)
    |> Repo.preload([:user, :tags, :picture])
  end

  def get_posts_without_pictures do
    Repo.all(
      from p in Post,
        left_join: pic in assoc(p, :picture),
        where: is_nil(pic.id),
        preload: [picture: pic]
    )
  end

  def get_empty_post do
    %Post{}
    |> Repo.preload([:tags])
  end

  def get_post_title(nil) do
    " - "
  end

  def get_post_title(post_id) do
    case MySuperApp.Blog.get_post!(post_id) do
      nil -> "Unnamed Post"
      post -> post.title
    end
  end

  def get_tag!(id), do: Repo.get!(Tag, id)

  def get_posts_by_user_id(user_id) do
    query =
      from(p in Post,
        where: p.user_id == ^user_id,
        order_by: [desc: p.updated_at],
        select: p
      )

    Repo.all(query) |> Repo.preload([:tags, :picture]) |> Enum.map(&Map.from_struct/1)
  end

  def get_all_posts() do
    query = from p in Post, order_by: [desc: p.updated_at], select: p

    Repo.all(query)
    |> Repo.preload([:tags, :picture, :user])
    |> Enum.map(&Map.from_struct/1)
  end

  def get_all_published_posts() do
    query = from p in Post, where: not is_nil(p.published_at), order_by: [asc: p.id], select: p

    Repo.all(query)
    |> Repo.preload([:tags, :picture, :user])
    |> Enum.map(&Map.from_struct/1)
  end

  def get_filtered_posts(filter, nil) do
    query =
      from(p in Post, where: ilike(p.body, ^"%#{filter}%") or ilike(p.title, ^"%#{filter}%"))

    Repo.all(query)
    |> Repo.preload([:tags, :picture])
    |> Enum.map(&Map.from_struct/1)
  end

  def get_filtered_posts(filter, user) do
    query =
      from(p in Post,
        where:
          p.user_id == ^user.id and
            (ilike(p.body, ^"%#{filter}%") or ilike(p.title, ^"%#{filter}%"))
      )

    Repo.all(query)
    |> Repo.preload([:tags, :picture])
    |> Enum.map(&Map.from_struct/1)
  end

  def get_filtered_published_posts(filter, nil) do
    query =
      from(p in Post,
        where:
          not is_nil(p.published_at) and
            (ilike(p.body, ^"%#{filter}%") or ilike(p.title, ^"%#{filter}%"))
      )

    Repo.all(query)
    |> Repo.preload([:tags, :picture])
    |> Enum.map(&Map.from_struct/1)
  end

  def get_filtered_published_posts(filter, user) do
    query =
      from(p in Post,
        where:
          p.user_id == ^user.id and not is_nil(p.published_at) and
            (ilike(p.body, ^"%#{filter}%") or ilike(p.title, ^"%#{filter}%"))
      )

    Repo.all(query)
    |> Repo.preload([:tags, :picture])
    |> Enum.map(&Map.from_struct/1)
  end

  def get_posts_by_tags(tag_names) do
    query =
      from p in Post,
        join: t in assoc(p, :tags),
        where: t.name in ^tag_names,
        distinct: p.id

    Repo.all(query)
    |> Repo.preload([:tags, :picture])
  end

  def get_posts_by_date(date_string) do
    date = get_date_from_string(date_string)

    from(p in Post, where: fragment("date(?) = ?", p.inserted_at, ^date))
    |> Repo.all()
    |> Repo.preload([:tags, :picture])
  end

  def get_posts_by_period(start_date, end_date) do
    from(p in Post, where: p.inserted_at >= ^start_date and p.inserted_at <= ^end_date)
    |> Repo.all()
    |> Repo.preload([:tags, :picture])
  end

  def get_tag_by_name(name) do
    case Repo.get_by(Tag, name: name) do
      nil ->
        case create_tag(%{name: name}) do
          {:ok, new_tag} -> new_tag
          {:error, _reason} -> nil
        end

      tag ->
        tag
    end
  end

  def get_username_by_post_id(nil) do
    " - "
  end

  def get_username_by_post_id(post_id) do
    Post
    |> Repo.get(post_id)
    |> case do
      nil ->
        "Post not found"

      post ->
        user = Repo.get(User, post.user_id)
        user.username
    end
  end

  def get_email_by_post_id(nil) do
    " - "
  end

  def get_email_by_post_id(post_id) do
    Post
    |> Repo.get(post_id)
    |> case do
      nil ->
        "Post not found"

      post ->
        user = Repo.get(User, post.user_id)
        user.email
    end
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tags, attrs["tags"] || attrs[:tags])
    |> Repo.insert()
  end

  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  def create_or_get_tag_by_name(name) do
    case Repo.get_by(Tag, name: name) do
      nil ->
        %Tag{}
        |> Tag.changeset(%{name: name})
        |> Repo.insert()

      tag ->
        tag
    end
  end

  def add_tags_to_post(tags, post) when is_list(tags) do
    post = post |> Repo.preload([:tags])
    existing_tags = post.tags
    updated_tags = Enum.uniq(existing_tags ++ tags)

    post
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, updated_tags)
    |> Repo.update!()
  end

  def add_tags_to_post(tag, post) do
    add_tags_to_post([tag], post)
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_post} -> {:ok, Repo.preload(updated_post, [:tags, :picture])}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update_post(id, attrs) do
    Repo.get!(Post, id)
    |> Repo.preload([:tags, :picture])
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tags, attrs[:tags])
    |> Repo.update()
  end

  def update_publication(post, attrs) do
    post
    |> Repo.preload([:tags, :picture])
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def map_tags_to_string(tags) do
    tags
    |> Enum.map_join(" ", fn tag -> tag.name end)
    |> String.trim()
  end

  def process_tags_string(tags_string) do
    tags_string
    |> String.split(" ")
    |> Enum.filter(fn tag_name -> tag_name != "" end)
    |> Enum.map(fn tag_name -> get_tag_by_name(tag_name) end)
  end

  def set_published_at(post) when post.published_at != nil do
    nil
  end

  def set_published_at(post) when post.published_at == nil do
    NaiveDateTime.utc_now()
  end

  defp get_date_from_string(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end
end
