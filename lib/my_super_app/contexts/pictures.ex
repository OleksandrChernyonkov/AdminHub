defmodule MySuperApp.Pictures do
  @moduledoc """
  The Pictures context.
  """

  import Ecto.Query, warn: false

  alias MySuperApp.{Repo, Picture, Accounts}

  @doc """
  Returns the list of pictures.

  ## Examples

      iex> list_pictures()
      [%Picture{}, ...]

  """

  def list_pictures(sort_order \\ :desc) do
    from(p in Picture,
      order_by: [{^sort_order, p.upload_at}]
    )
    |> Repo.all()
    |> Repo.preload(post: :user)
  end

  @doc """
  Gets a single picture.

  Raises `Ecto.NoResultsError` if the Picture does not exist.

  ## Examples

      iex> get_picture!(123)
      %Picture{}

      iex> get_picture!(456)
      nil

  """

  def get_picture(id) do
    Repo.get(Picture, id)
    |> case do
      %Picture{} = picture -> Repo.preload(picture, post: :user)
      nil -> nil
    end
  end

  @doc """
  Creates a picture.

  ## Examples

      iex> create_picture(%{field: value})
      {:ok, %Picture{}}

      iex> create_picture(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_picture(attrs \\ %{}) do
    %Picture{}
    |> Picture.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, picture} ->
        picture_with_post = Repo.preload(picture, post: :user)
        broadcast({:ok, picture_with_post}, :picture_created)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def broadcast({:ok, picture}, tag) do
    Phoenix.PubSub.broadcast(
      MySuperApp.PubSub,
      "pictures",
      {tag, picture}
    )

    {:ok, picture}
  end

  def broadcast({:error, _reason} = error, _tag), do: error

  def subscribe do
    Phoenix.PubSub.subscribe(MySuperApp.PubSub, "pictures")
  end

  @doc """
  Updates a picture.

  ## Examples

      iex> update_picture(picture, %{field: new_value})
      {:ok, %Picture{}}

      iex> update_picture(picture, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def update_picture(%Picture{} = picture, attrs) do
    picture
    |> Picture.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_picture} ->
        broadcast({:ok, updated_picture |> Repo.preload(post: :user)}, :picture_updated)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_picture_api(%Picture{} = picture, attrs) do
    picture
    |> Picture.changeset(attrs)
    |> Repo.update()
  end

  def get_picture_name(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> Path.basename()
  end

  @doc """
  Deletes a picture.

  ## Examples

      iex> delete_picture(picture)
      {:ok, %Picture{}}

      iex> delete_picture(picture)
      {:error, %Ecto.Changeset{}}

  """
  def delete_picture(%Picture{} = picture) do
    Repo.delete(picture)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking picture changes.

  ## Examples

      iex> change_picture(picture)
      %Ecto.Changeset{data: %Picture{}}

  """

  def change_picture(%Picture{} = picture, attrs \\ %{}) do
    Picture.changeset(picture, attrs)
  end

  def filter_by_post_id(pictures, "") do
    pictures
  end

  def filter_by_post_id(pictures, "-") do
    Enum.filter(pictures, fn picture -> picture.post == nil end)
  end

  def filter_by_post_id(pictures, post_id) do
    case Integer.parse(post_id) do
      {id, ""} ->
        pictures
        |> Repo.preload(post: :user)
        |> Enum.filter(fn picture -> picture.post_id == id end)

      _ ->
        []
    end
  end

  def filter_by_post_title(pictures, "") do
    pictures
  end

  def filter_by_post_title(pictures, "-") do
    pictures
    |> Enum.filter(fn picture -> picture.post == nil end)
  end

  def filter_by_post_title(pictures, post_title) do
    post_title_upcase = String.upcase(post_title)

    Enum.filter(pictures, fn
      %{post: %{title: title}} -> String.contains?(String.upcase(title), post_title_upcase)
      _ -> false
    end)
  end

  def filter_by_file_name(pictures, "") do
    pictures
  end

  def filter_by_file_name(pictures, file_name) do
    Enum.filter(pictures, fn picture ->
      String.contains?(String.upcase(picture.file_name), String.upcase(file_name))
    end)
  end

  def filter_by_author_email(pictures, "") do
    pictures
  end

  def filter_by_author_email(pictures, "-") do
    pictures
    |> Enum.filter(fn picture -> picture.post == nil end)
  end

  def filter_by_author_email(pictures, author_email) do
    author_email_upcase = String.upcase(author_email)

    Enum.filter(pictures, fn
      %{post: %{user_id: user_id}} ->
        user = Accounts.get_user!(user_id)
        String.contains?(String.upcase(user.email), author_email_upcase)

      _ ->
        false
    end)
  end

  def filtered_pictures(pictures, filters) do
    pictures
    |> filter_by_post_id(filters.post_id)
    |> filter_by_post_title(filters.post_title)
    |> filter_by_file_name(filters.file_name)
    |> filter_by_author_email(filters.author_email)
  end

  def search_by_params(pictures, search_params) do
    (filter_by_post_id(pictures, search_params) ++
       filter_by_post_title(pictures, search_params) ++
       filter_by_file_name(pictures, search_params) ++
       filter_by_author_email(pictures, search_params))
    |> Enum.uniq()
  end

  def sort_by_asc(pictures) do
    Enum.sort_by(pictures, & &1.upload_at, :asc)
  end

  def sort_by_desc(pictures) do
    Enum.sort_by(pictures, & &1.upload_at, :desc)
  end

  def get_pictures_by_period(start_date_time, end_date_time) do
    from(p in Picture,
      where: p.upload_at >= ^start_date_time and p.upload_at <= ^end_date_time,
      preload: [post: :user]
    )
    |> Repo.all()
  end

  def get_pictures_by_post_id(post_id) do
    from(p in Picture,
      where: p.post_id == ^post_id,
      preload: [post: :user]
    )
    |> Repo.all()
  end

  def get_pictures_by_author_name(author_name) do
    from(p in Picture,
      join: post in assoc(p, :post),
      join: user in assoc(post, :user),
      where: user.username == ^author_name,
      preload: [post: :user]
    )
    |> Repo.all()
  end

  def get_pictures_by_author_email(author_email) do
    from(p in Picture,
      join: post in assoc(p, :post),
      join: user in assoc(post, :user),
      where: user.email == ^author_email,
      preload: [post: :user]
    )
    |> Repo.all()
  end
end
