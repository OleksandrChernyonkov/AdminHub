defmodule MySuperApp.PicturesTest do
  use MySuperApp.DataCase

  alias MySuperApp.Pictures
  alias MySuperApp.Picture

  @valid_attrs %{
    file_name: "image.png",
    post_id: nil,
    path: "path_string",
    upload_at: DateTime.utc_now()
  }
  @valid_attrs2 %{
    file_name: "image2.png",
    post_id: nil,
    path: "path_string2",
    upload_at: DateTime.utc_now()
  }
  @update_attrs %{file_name: "updated_image.png"}
  @invalid_attrs %{file_name: nil}

  describe "list_pictures" do
    test "returns all pictures" do
      {:ok, picture} = Pictures.create_picture(@valid_attrs)
      assert Pictures.list_pictures() == [picture]
    end
  end

  describe "get_picture" do
    test "returns the picture with given id" do
      {:ok, picture} = Pictures.create_picture(@valid_attrs)
      assert Pictures.get_picture(picture.id) == picture
    end

    test "returns nil if the picture does not exist" do
      assert Pictures.get_picture(-1) == nil
    end
  end

  describe "create_picture" do
    test "creates a picture with valid attributes" do
      assert {:ok, %Picture{} = picture} = Pictures.create_picture(@valid_attrs)
      assert picture.file_name == @valid_attrs.file_name
    end

    test "does not create a picture with invalid attributes" do
      assert {:error, _changeset} = Pictures.create_picture(@invalid_attrs)
    end
  end

  describe "update_picture" do
    test "updates a picture with valid attributes" do
      {:ok, picture} = Pictures.create_picture(@valid_attrs)
      assert {:ok, %Picture{} = picture} = Pictures.update_picture(picture, @update_attrs)
      assert picture.file_name == @update_attrs.file_name
    end

    test "does not update the picture with invalid attributes" do
      {:ok, picture} = Pictures.create_picture(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Pictures.update_picture(picture, @invalid_attrs)
    end
  end

  describe "delete_picture" do
    test "deletes the picture" do
      {:ok, picture} = Pictures.create_picture(@valid_attrs)
      assert {:ok, %Picture{}} = Pictures.delete_picture(picture)
      assert Pictures.get_picture(picture.id) == nil
    end
  end

  describe "filter_by_post_id" do
    test "filters pictures by post_id" do
      {:ok, _picture1} = Pictures.create_picture(@valid_attrs)
      {:ok, _picture2} = Pictures.create_picture(@valid_attrs2)
      pictures = Pictures.list_pictures()

      filtered_empty = Pictures.filter_by_post_id(pictures, "3")
      assert filtered_empty == []
    end

    test "return all pictures when post_id is empty" do
      {:ok, _picture1} = Pictures.create_picture(@valid_attrs)
      {:ok, _picture2} = Pictures.create_picture(@valid_attrs2)
      pictures = Pictures.list_pictures()

      assert Pictures.filter_by_post_id(pictures, "") == pictures
    end
  end
end
