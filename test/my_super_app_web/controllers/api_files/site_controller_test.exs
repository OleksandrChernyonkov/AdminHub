defmodule MySuperAppWeb.ApiFiles.SiteControllerTest do
  use MySuperAppWeb.ConnCase

  import MySuperApp.CasinosAdminsFixtures

  @valid_attrs %{brand: "site_brand", status: "ACTIVE", operator: "operator_name"}
  @updated_attrs %{brand: "new_site_brand"}
  @invalid_attrs %{brand: nil}

  setup %{conn: conn} do
    site = site_fixture()
    {:ok, conn: conn, site: site}
  end

  describe "show" do
    test "returns the requested site", %{conn: conn, site: site} do
      conn = get(conn, "/api/sites/#{site.id}")

      assert json_response(conn, 200)["data"]["id"] == site.id
      assert json_response(conn, 200)["data"]["brand"] == site.brand
    end

    test "returns 404 when the site does not exist", %{conn: conn} do
      conn = get(conn, "/api/sites/#{-1}")

      assert json_response(conn, 404)["error"] == "Site not found"
    end
  end

  describe "index" do
    test "returns all sites", %{conn: conn, site: site} do
      conn = get(conn, "/api/sites/")
      lonely_site = assert json_response(conn, 200)["data"] |> List.first()

      assert json_response(conn, 200)["data"] |> is_list()
      assert lonely_site["brand"] == site.brand
    end

    test "returns sites by operator_name", %{conn: conn, site: site} do
      conn = get(conn, "/api/sites?operator=#{site.operator.name}")

      assert json_response(conn, 200)["data"]
             |> Enum.any?(fn param -> param["id"] == site.id end)
    end

    test "returns sites by date", %{conn: conn} do
      conn = get(conn, "/api/sites?date=2024-01-01")
      assert json_response(conn, 200)["data"] |> is_list()
    end

    test "returns sites by period", %{conn: conn} do
      conn =
        get(
          conn,
          "/api/sites?start_date_time=2024-01-01T00:00:00Z&end_date_time=2024-01-02T00:00:00Z"
        )

      assert json_response(conn, 200)["data"] |> is_list()
    end
  end

  describe "create" do
    test "creates a site and returns it", %{conn: conn} do
      conn = post(conn, "/api/sites", site: @valid_attrs)
      response_data = json_response(conn, 201)["data"]

      assert response_data["brand"] == @valid_attrs.brand
    end

    test "returns 422 with errors when site creation fails", %{conn: conn} do
      conn = post(conn, "/api/sites", site: @invalid_attrs)
      response_data = json_response(conn, 422)

      assert conn.status == 422
      assert %{"errors" => errors} = response_data
      assert %{"field" => "brand", "message" => "can't be blank"} in errors
    end
  end

  describe "update" do
    test "updates a site and returns it", %{conn: conn, site: site} do
      conn = put(conn, "/api/sites/#{site.id}", site: @updated_attrs)
      response_data = json_response(conn, 200)["data"]

      assert response_data["brand"] == @updated_attrs.brand
    end

    test "returns 404 when the site does not exist", %{conn: conn} do
      conn = put(conn, "/api/sites/#{-1}", site: %{brand: "new_site_brand"})
      response_data = json_response(conn, 404)

      assert conn.status == 404
      assert response_data["error"] == "Site not found"
    end

    test "returns 422 with errors when site update fails", %{conn: conn, site: site} do
      conn = put(conn, "/api/sites/#{site.id}", site: @invalid_attrs)
      response_data = json_response(conn, 422)

      assert conn.status == 422
      assert %{"errors" => errors} = response_data
      assert %{"field" => "brand", "message" => "can't be blank"} in errors
    end
  end

  describe "delete" do
    test "deletes the site and returns no content", %{conn: conn, site: site} do
      conn = delete(conn, "/api/sites/#{site.id}")
      assert conn.status == 204

      conn = get(conn, "/api/sites/#{site.id}")
      assert conn.status == 404
    end

    test "returns 404 when the site does not exist", %{conn: conn} do
      conn = delete(conn, "/api/sites/#{-1}")
      response_data = json_response(conn, 404)

      assert conn.status == 404
      assert response_data["error"] == "Site not found"
    end
  end
end
