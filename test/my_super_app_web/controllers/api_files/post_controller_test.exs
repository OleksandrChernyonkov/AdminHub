defmodule MySuperAppWeb.PostControllerTest do
  use MySuperAppWeb.ConnCase

  import MySuperApp.BlogFixtures

  @create_attrs %{
    title: "some title",
    body: "some body",
    tags: []
  }

  @invalid_attrs %{title: nil, body: nil, tags: []}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all posts", %{conn: conn} do
      conn = get(conn, ~p"/api/posts")
      response_data = json_response(conn, 200)["data"]
      assert response_data == []
    end

    test "lists all posts when posts exist", %{conn: conn} do
      post_1 = post_fixture(%{title: "Post 1", body: "Body of post 1"})
      post_2 = post_fixture(%{title: "Post 2", body: "Body of post 2"})
      conn = get(conn, ~p"/api/posts")
      response_data = json_response(conn, 200)["data"]

      assert length(response_data) == 2
      assert Enum.any?(response_data, fn post -> post["title"] == post_1.title end)
      assert Enum.any?(response_data, fn post -> post["title"] == post_2.title end)
    end
  end

  describe "create post" do
    test "renders post when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/posts", post: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/posts/#{id}")

      assert %{
               "id" => ^id,
               "body" => "some body",
               "title" => "some title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/posts", post: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete post" do
    setup [:create_post]

    test "deletes chosen post", %{conn: conn, post: post} do
      conn = delete(conn, ~p"/api/posts/#{post.id}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/posts/#{post.id}")
      end
    end
  end

  defp create_post(_) do
    post = post_fixture()
    %{post: post}
  end
end
