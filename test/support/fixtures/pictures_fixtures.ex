defmodule MySuperApp.PicturesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MySuperApp.Pictures` context.
  """
  alias MySuperApp.{Repo, Pictures, Blog.Post, User}

  @doc """
  Generate a picture.
  """
  def picture_fixture(attrs \\ %{}) do
    user =
      Repo.insert!(%User{
        username: "some_user",
        email: "user@example.com",
        hashed_password: "hashed_password_stub"
      })

    post =
      Repo.insert!(%Post{
        title: "some_title",
        body: "some_body",
        user_id: user.id
      })

    {:ok, picture} =
      attrs
      |> Enum.into(%{
        file_name: "some_picture",
        path:
          "https://cayman4010.s3.eu-north-1.amazonaws.com/3140adf4-3c12-490f-a4d6-5651ed755ae4-3.jpg",
        post_id: post.id,
        upload_at: NaiveDateTime.utc_now()
      })
      |> Pictures.create_picture()

    picture
    |> Repo.preload(post: [:user])
  end
end
