defmodule MySuperAppWeb.PictureJSON do
  alias MySuperApp.Picture

  @doc """
  Renders a list of pictures.
  """
  def index(%{pictures: pictures}) do
    %{data: for(picture <- pictures, do: data(picture))}
  end

  @doc """
  Renders a single picture.
  """
  def show_path(%{picture: picture}) do
    %{path: path(picture)}
  end

  def show_paths(%{pictures: pictures}) do
    %{paths: for(picture <- pictures, do: paths(picture))}
  end

  def show(%{picture: picture}) do
    %{data: data(picture)}
  end

  def path(%Picture{} = picture) do
    %{path: picture.path}
  end

  def paths(%Picture{} = picture) do
    %{path: picture.path}
  end

  def update(%Picture{} = picture) do
    %{
      id: picture.id,
      file_name: picture.file_name,
      path: picture.path,
      upload_at: picture.upload_at,
      post_id: picture.post_id
    }
  end

  defp data(%Picture{} = picture) do
    post_title = if picture.post, do: picture.post.title, else: nil
    user_email = if picture.post && picture.post.user, do: picture.post.user.email, else: nil
    user_id = if picture.post && picture.post.user, do: picture.post.user.id, else: nil

    %{
      id: picture.id,
      file_name: picture.file_name,
      path: picture.path,
      upload_at: picture.upload_at,
      post_id: picture.post_id,
      post_title: post_title,
      user_email: user_email,
      user_id: user_id
    }
  end
end
