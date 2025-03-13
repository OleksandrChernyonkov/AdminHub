defmodule MySuperAppWeb.PicturesLive do
  use MySuperAppWeb, :admin_live_view

  alias MySuperApp.{Pictures, Picture, Accounts, Blog, CasinosAdmins}
  alias ExAws.S3
  require Logger

  @access_key_id System.get_env("AWS_ACCESS_KEY_ID")
  @secret_access_key System.get_env("AWS_SECRET_ACCESS_KEY")
  @s3_region System.get_env("AWS_REGION")
  @bucket System.get_env("AWS_BUCKET_NAME")

  def mount(_params, session, socket) do
    if connected?(socket), do: Pictures.subscribe()

    socket =
      assign(socket,
        form: to_form(Pictures.change_picture(%Picture{})),
        add_picture_modal: false,
        current_user: Accounts.get_user_by_session_token(session["user_token"]),
        selected_picture_id: nil,
        posts_without_pictures: Blog.get_posts_without_pictures(),
        filters: %{
          post_id: "",
          post_title: "",
          file_name: "",
          author_email: ""
        },
        search_params: "",
        all_pictures: Pictures.list_pictures(),
        filtered_pictures: Pictures.list_pictures()
      )

    socket =
      allow_upload(
        socket,
        :pictures,
        accept: ~w(image/*),
        max_entries: 1,
        max_file_size: 10 * 1024 * 1024 * 1024
      )

    {:ok, stream(socket, :pictures, socket.assigns.all_pictures)}
  end

  def handle_event("total_search", %{"value" => search_params}, socket) do
    searched_pictures = Pictures.search_by_params(socket.assigns.all_pictures, search_params)

    {:noreply,
     socket
     |> stream(:pictures, searched_pictures, reset: true)
     |> assign(filtered_pictures: searched_pictures, search_params: search_params)}
  end

  def handle_event("filter_by_post_id", %{"value" => post_id}, socket) do
    new_filters = Map.put(socket.assigns.filters, :post_id, post_id)
    filtered_pictures = Pictures.filtered_pictures(socket.assigns.all_pictures, new_filters)

    {:noreply,
     socket
     |> stream(:pictures, filtered_pictures, reset: true)
     |> assign(filtered_pictures: filtered_pictures, filters: new_filters)}
  end

  def handle_event("filter_by_post_title", %{"value" => post_title}, socket) do
    new_filters = Map.put(socket.assigns.filters, :post_title, post_title)
    filtered_pictures = Pictures.filtered_pictures(socket.assigns.all_pictures, new_filters)

    {:noreply,
     socket
     |> stream(:pictures, filtered_pictures, reset: true)
     |> assign(filtered_pictures: filtered_pictures, filters: new_filters)}
  end

  def handle_event("filter_by_file_name", %{"value" => file_name}, socket) do
    new_filters = Map.put(socket.assigns.filters, :file_name, file_name)
    filtered_pictures = Pictures.filtered_pictures(socket.assigns.all_pictures, new_filters)

    {:noreply,
     socket
     |> stream(:pictures, filtered_pictures, reset: true)
     |> assign(filtered_pictures: filtered_pictures, filters: new_filters)}
  end

  def handle_event("filter_by_author_email", %{"value" => author_email}, socket) do
    new_filters = Map.put(socket.assigns.filters, :author_email, author_email)
    filtered_pictures = Pictures.filtered_pictures(socket.assigns.all_pictures, new_filters)

    {:noreply,
     socket
     |> stream(:pictures, filtered_pictures, reset: true)
     |> assign(filtered_pictures: filtered_pictures, filters: new_filters)}
  end

  def handle_event("sort_newest", _params, socket) do
    {:noreply,
     socket
     |> stream(:pictures, Pictures.sort_by_desc(socket.assigns.filtered_pictures), reset: true)
     |> assign(filtered_pictures: Pictures.sort_by_desc(socket.assigns.filtered_pictures))}
  end

  def handle_event("sort_oldest", _params, socket) do
    {:noreply,
     socket
     |> stream(:pictures, Pictures.sort_by_asc(socket.assigns.filtered_pictures), reset: true)
     |> assign(filtered_pictures: Pictures.sort_by_asc(socket.assigns.filtered_pictures))}
  end

  def handle_event("open_replace_picture_modal", %{"id" => picture_id}, socket) do
    {:noreply, assign(socket, :selected_picture_id, picture_id)}
  end

  def handle_event("replace_picture", %{"picture_id" => picture_id}, socket) do
    picture = Pictures.get_picture(picture_id)
    Logger.info("Replacing picture with ID: #{picture_id}")

    path =
      consume_uploaded_entries(socket, :pictures, fn meta, entry ->
        dest = "#{entry.uuid}-#{entry.client_name}"

        case upload_to_s3(meta.path, dest) do
          {:ok, _response} ->
            url_path = "https://#{@bucket}.s3.#{@s3_region}.amazonaws.com/#{dest}"
            Logger.info("File uploaded successfully to #{url_path}")
            {:ok, url_path}

          {:error, reason} ->
            Logger.error("Failed to upload to S3: #{inspect(reason)}")
            {:error, reason}
        end
      end)

    updated_params = %{
      file_name: Pictures.get_picture_name(List.first(path)),
      upload_at: NaiveDateTime.utc_now(),
      path: List.first(path),
      post_id: picture.post_id
    }

    Pictures.update_picture(picture, updated_params)

    {:noreply, socket |> assign(selected_picture_id: nil)}
  end

  def handle_event("close_replace_picture_modal", _params, socket) do
    {:noreply, assign(socket, :selected_picture_id, nil)}
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :pictures, ref)}
  end

  def handle_event("validate", _, socket) do
    photos_upload_errors =
      Enum.map(socket.assigns.uploads.pictures.entries, fn entry ->
        if entry.valid?, do: nil, else: {:error, entry.client_name}
      end)
      |> Enum.reject(&is_nil/1)

    socket =
      if Enum.empty?(photos_upload_errors) do
        assign(socket, :photos_upload_errors, [])
      else
        assign(socket, :photos_upload_errors, photos_upload_errors)
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    picture = Pictures.get_picture(id)

    case Pictures.delete_picture(picture) do
      {:ok, _picture} ->
        new_pictures = Pictures.list_pictures()

        socket =
          socket
          |> stream_delete(:pictures, picture)
          |> stream(:pictures, new_pictures, reset: true)
          |> assign(
            posts_without_pictures: Blog.get_posts_without_pictures(),
            all_pictures: new_pictures,
            filtered_pictures: new_pictures
          )

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  def handle_event("save_from_modal", %{"post_id" => post_id}, socket) do
    path =
      consume_uploaded_entries(socket, :pictures, fn meta, entry ->
        dest = "#{entry.uuid}-#{entry.client_name}"

        case upload_to_s3(meta.path, dest) do
          {:ok, _response} ->
            url_path = "https://#{@bucket}.s3.#{@s3_region}.amazonaws.com/#{dest}"
            Logger.info("File uploaded successfully to #{url_path}")
            {:ok, url_path}

          {:error, reason} ->
            Logger.error("Failed to upload to S3: #{inspect(reason)}")
            {:error, reason}
        end
      end)

    params = %{
      file_name: Pictures.get_picture_name(List.first(path)),
      upload_at: NaiveDateTime.utc_now(),
      path: List.first(path),
      post_id:
        if post_id == "" do
          nil
        else
          post_id
        end
    }

    case Pictures.create_picture(params) do
      {:ok, _picture} ->
        changeset = Pictures.change_picture(%Picture{})
        new_pictures = Pictures.list_pictures()

        socket =
          socket
          |> put_flash(:info, "added picture!")
          |> stream(:pictures, new_pictures, reset: true)
          |> assign(
            add_picture_modal: false,
            posts_without_pictures: Blog.get_posts_without_pictures(),
            all_pictures: new_pictures,
            filtered_pictures: new_pictures
          )

        {:noreply, assign_form(socket, changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("open_add_picture_modal", _params, socket) do
    {:noreply, assign(socket, add_picture_modal: true)}
  end

  def handle_event("close_add_picture_modal", _params, socket) do
    {:noreply, assign(socket, add_picture_modal: false)}
  end

  def handle_event("reset_fields", _params, socket) do
    socket =
      socket
      |> stream(:pictures, socket.assigns.all_pictures, reset: true)
      |> assign(
        filtered_pictures: socket.assigns.all_pictures,
        filters: %{
          post_id: "",
          post_title: "",
          file_name: "",
          author_email: ""
        },
        search_params: ""
      )

    {:noreply, socket}
  end

  def handle_info({:picture_created, picture}, socket) do
    {:noreply, stream_insert(socket, :pictures, picture, at: 0)}
  end

  def handle_info({:picture_updated, picture}, socket) do
    {:noreply, stream_insert(socket, :pictures, picture, at: 0)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp upload_to_s3(source_path, dest_path) do
    config = %{
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key,
      region: @s3_region
    }

    source_path
    |> ExAws.S3.Upload.stream_file()
    |> S3.upload(@bucket, dest_path)
    |> ExAws.request(config: config)
    |> case do
      {:ok, response} ->
        Logger.info("Uploaded to S3: #{dest_path}")
        {:ok, response}

      {:error, reason} ->
        Logger.error("Error uploading to S3: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
