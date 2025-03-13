defmodule MySuperAppWeb.PictureControllerTest do
  use MySuperAppWeb.ConnCase

  import MySuperApp.PicturesFixtures

  @updated_attrs %{path: "http://example.com/new_picture.jpg"}

  setup %{conn: conn} do
    {:ok, conn: conn, picture: picture_fixture()}
  end

  describe "index" do
    test "returns a list of pictures", %{conn: conn} do
      conn = get(conn, "/api/pictures")
      response_data = json_response(conn, 200)["data"]

      assert response_data |> is_list()
    end

    test "returns pictures by post_id", %{conn: conn, picture: picture} do
      conn = get(conn, "/api/pictures?post_id=#{picture.post_id}")

      assert json_response(conn, 200)["data"]
             |> Enum.any?(fn param -> param["id"] == picture.id end)
    end

    test "returns pictures by author_name", %{conn: conn, picture: picture} do
      conn = get(conn, "/api/pictures?author_name=#{picture.post.user.username}")

      assert json_response(conn, 200)["data"]
             |> Enum.any?(fn param -> param["id"] == picture.id end)
    end

    test "returns pictures by date range", %{conn: conn} do
      conn = get(conn, "/api/pictures?start_date=2024-01-01&end_date=2024-01-02")
      assert json_response(conn, 200)["data"] |> is_list()
    end
  end

  describe "update" do
    @updated_attrs %{url: "new_path"}

    test "updates a picture and returns it", %{conn: conn, picture: picture} do
      conn = put(conn, "/api/pictures/#{picture.id}", %{"url" => @updated_attrs.url})
      response_data = json_response(conn, 200)["data"]

      assert response_data["path"] == @updated_attrs.url
    end

    test "returns 422 with errors when picture update fails", %{conn: conn, picture: picture} do
      conn = put(conn, "/api/pictures/#{picture.id}", %{"url" => nil})
      response_data = json_response(conn, 422)

      assert conn.status == 422
      assert %{"errors" => errors} = response_data
      assert %{"field" => "path", "message" => "can't be blank"} in errors
    end
  end

  describe "delete" do
    test "deletes the picture and returns no content", %{conn: conn, picture: picture} do
      conn = delete(conn, "/api/pictures/#{picture.id}")
      assert conn.status == 204

      conn = get(conn, "/api/pictures", %{"picture_id" => "#{picture.id}"})
      assert conn.status == 404
      assert json_response(conn, 404)["error"] == "Picture not found"
    end

    test "returns 404 when the picture does not exist", %{conn: conn} do
      conn = delete(conn, "/api/pictures/#{-1}")
      response_data = json_response(conn, 404)

      assert conn.status == 404
      assert response_data["error"] == "Picture not found"
    end
  end
end
