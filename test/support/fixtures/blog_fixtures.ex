defmodule MySuperApp.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MySuperApp.Blog` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        body: "some body",
        title: "some title",
        tags: [%MySuperApp.Tag{name: "tag"}],
        user: %MySuperApp.User{username: "user", email: "u@gmail.com"},
        picture: %MySuperApp.Picture{
          file_name: "test_name.jpg",
          path:
            "https://cayman4010.s3.eu-north-1.amazonaws.com/3140adf4-3c12-490f-a4d6-5651ed755ae4-3.jpg"
        }
      })
      |> MySuperApp.Blog.create_post()

    post
    |> MySuperApp.Repo.preload([:user, :tags, :picture])
  end
end
