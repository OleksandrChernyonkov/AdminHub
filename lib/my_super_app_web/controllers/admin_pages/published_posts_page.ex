defmodule MySuperAppWeb.PublishedPostsPage do
  import Surface
  use MySuperAppWeb, :admin_surface_live_view
  alias Moon.Design.{Button, Table, Drawer, Form, Modal, Pagination, Search, Dropdown, Chip}
  alias Moon.Design.Table.Column
  alias Moon.Design.Form.{Input, Field}
  alias Moon.Icon
  alias MySuperApp.{CasinosAdmins, Blog, Blog.Post, Accounts}
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  @moduledoc """
  Module for rendering admin page
  """
  def mount(_params, session, socket) do
    form =
      %Post{}
      |> Post.changeset(%{})
      |> to_form()

    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     assign(socket,
       posts: Blog.get_all_published_posts(),
       post: Blog.get_empty_post(),
       operator_name: nil,
       form: form,
       changeset: Post.changeset(%Post{}, %{}),
       operator_id: current_user.operator_id,
       operator: CasinosAdmins.get_operator(current_user.operator_id),
       operator_modal: nil,
       selected: nil,
       update_selected: nil,
       post_modal: nil,
       current_page: 1,
       limit: 10,
       sort: [name: "ASC"],
       total_pages:
         Blog.get_all_published_posts() |> Enum.count() |> CasinosAdmins.page_count(10),
       filter: "",
       current_user: current_user,
       post_changeset: Post.changeset(%Post{}, %{body: nil, title: nil, tags: nil}),
       choose_author: "all authors",
       update_params: %{}
     )}
  end

  def handle_event("row_click", %{"selected" => selected}, socket) do
    {:noreply,
     assign(socket, selected: selected, update_selected: selected, post: Blog.get_post(selected))}
  end

  def handle_event("update_validate", %{"post" => params}, socket) do
    params =
      params
      |> Map.put(
        "user_id",
        Accounts.get_user_id_by_name(params["user_id"])
      )
      |> CasinosAdmins.string_keys_to_atom_keys()

    {:noreply, assign(socket, update_params: params)}
  end

  def handle_event("update_post_by_click", _value, socket) do
    Drawer.close("update_drawer")

    case Blog.update_post(
           String.to_integer(socket.assigns.selected),
           socket.assigns.update_params
           |> Map.put(:tags, Blog.process_tags_string(socket.assigns.update_params.tags))
         ) do
      {:ok, post} ->
        {:noreply,
         assign(
           socket |> put_flash(:info, "Updated!"),
           post: post,
           posts: Blog.get_all_published_posts(),
           update_selected: nil
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, update_selected: nil)}
    end
  end

  def handle_event("open_delete_modal", %{"value" => selected}, socket) do
    Modal.open("modal")
    post_modal = Blog.get_post(String.to_integer(selected))
    {:noreply, assign(socket, post_modal: post_modal)}
  end

  def handle_event("close_update_drawer", _params, socket) do
    Drawer.close("update_drawer")
    {:noreply, assign(socket, update_selected: nil)}
  end

  def handle_event("close_update_drawer_on_close", _, socket) do
    {:noreply, assign(socket, update_selected: nil, form: to_form(Post.changeset(%Post{}, %{})))}
  end

  def handle_event("approve_delete", %{"value" => post_id}, socket) do
    Modal.close("modal")
    id = String.to_integer(post_id)
    post = Blog.get_post(id)

    Blog.delete_post(post)

    new_page =
      if rem(Enum.count(Blog.get_all_published_posts()), socket.assigns.limit) == 0 and
           socket.assigns.current_page ==
             CasinosAdmins.page_count(
               Enum.count(Blog.get_all_published_posts()),
               socket.assigns.limit
             ) + 1 do
        socket.assigns.current_page - 1
      else
        socket.assigns.current_page
      end

    {:noreply,
     assign(
       socket |> put_flash(:info, "post deleted!"),
       post_modal: nil,
       posts: Blog.get_all_published_posts(),
       current_page: new_page
     )}
  end

  def handle_event("close_modal", _, socket) do
    Modal.close("modal")
    {:noreply, assign(socket, post_modal: nil)}
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(
       current_page: current_page,
       posts_10: CasinosAdmins.get_models_limit(socket.assigns, socket.assigns.posts)
     )}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    user = Accounts.get_user_by_name(socket.assigns.choose_author)
    posts = Blog.get_filtered_published_posts(filter, user)

    {:noreply, assign(socket, filter: filter, posts: posts)}
  end

  def handle_event("clear", _, socket) do
    posts = Blog.get_filtered_published_posts("", nil)
    {:noreply, assign(socket, filter: "", choose_author: "all authors", posts: posts)}
  end

  def handle_event("change_pagination", %{"value" => limit}, socket) do
    total_pages = CasinosAdmins.page_count(Enum.count(socket.assigns.posts), socket.assigns.limit)

    {:noreply, assign(socket, limit: String.to_integer(limit), total_pages: total_pages)}
  end

  def handle_event(
        "handle_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    posts = CasinosAdmins.sort_list(socket.assigns.posts, String.to_atom(sort_key), sort_dir)

    {:noreply, socket |> assign(sort: ["#{sort_key}": sort_dir], posts: posts)}
  end

  def handle_event("change_author", %{"value" => "all authors"}, socket) do
    posts = Blog.get_filtered_published_posts(socket.assigns.filter, nil)
    {:noreply, assign(socket, posts: posts, choose_author: "all authors")}
  end

  def handle_event("change_author", %{"value" => author_name}, socket) do
    user = Accounts.get_user_by_name(author_name)

    posts = Blog.get_filtered_published_posts(socket.assigns.filter, user)
    {:noreply, assign(socket, posts: posts, choose_author: author_name)}
  end

  def handle_event("publish_post", %{"value" => post_id}, socket) do
    post = Blog.get_post(post_id)

    case Blog.update_publication(post, %{published_at: Blog.set_published_at(post)}) do
      {:ok, _post} ->
        {:noreply, assign(socket, posts: Blog.get_all_published_posts())}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def disabled_editing?(current_user, post) do
    cond do
      current_user.role.permission_id == 4 -> false
      current_user.id == post.user_id -> false
      true -> true
    end
  end

  def disabled?(current_user, post) do
    cond do
      current_user.role.permission_id == 4 ->
        false

      current_user.id == post.user_id ->
        false

      current_user.role.permission_id == 3 and
          Map.get(post.user, :operator_id, nil) == current_user.operator_id ->
        false

      true ->
        true
    end
  end

  def render(assigns) do
    ~F"""
    <div class="flex gap-2 mb-3 h-full">
      <Dropdown id="dropdown_post_author" on_change="change_author" class="w-[25%]">
        <Dropdown.Options titles={["all_authors"] ++ Accounts.get_users_names()} />
        <Dropdown.Trigger :let={value: value}>
          <Chip class="w-full justify-center border border-trunks truncate">{value || @choose_author}</Chip>
        </Dropdown.Trigger>
      </Dropdown>
      <Search
        id="default-search"
        {=@filter}
        on_keyup="change_filter"
        options={[]}
        class="w-[70%]"
        prompt="Search by title or body"
      >
        <Dropdown id="1" disabled>
          <Dropdown.Trigger disabled />
        </Dropdown></Search>
      <Button class="close-button" on_click="clear">Clear all</Button>
    </div>

    <Drawer id="update_drawer" is_open={@update_selected} on_close="close_update_drawer_on_close">
      <Drawer.Panel>
        <Form for={@form} change="update_validate">
          <div class="mx-4">
            <Field field={:title} class="text-moon-30 font-medium mb-4">
              <br>
              <div class="text-2xl font-bold text-center mt-2 mb-2">
                Correct post`s title
              </div>
              <div>
                <Input placeholder="Title" value={@post.title} class="text-center" />
              </div>
            </Field>

            <Field field={:body} class="text-moon-30 font-medium mb-4">
              <div class="text-2xl font-bold text-center mt-2 mb-2">
                Correct post`s body
              </div>
              <div>
                <Input placeholder="Body" value={@post.body} class="text-center" />
              </div>
            </Field>

            <Field field={:tags} class="text-moon-30 font-medium mb-4">
              <div class="text-2xl font-bold text-center mt-2 mb-2">
                Correct post`s tags
              </div>
              <div>
                <Input placeholder="Body" value={Blog.map_tags_to_string(@post.tags)} class="text-center" />
              </div>
            </Field>

            <Field field={:user_id} class="text-moon-30 font-medium">
              <div class="text-2xl font-bold text-center mt-2 mb-2">
                User
              </div>
              <Input
                class="text-center"
                value={Accounts.get_user_name(@post.user_id)}
                readonly
                placeholder={Accounts.get_user_name(@post.user_id)}
              />
            </Field>

            <div class="mb-4">
              <div class="text-2xl font-bold text-center mt-2 mb-2">
              </div>
              <div class="flex justify-center">
                {#if @post.picture && Ecto.assoc_loaded?(@post.picture)}
                  <img src={@post.picture.path} alt="Current post image" class="w-64 h-48 object-cover">
                {#else}
                  <span>No image</span>
                {/if}
              </div>
            </div>

            <div class="p-2 border-t-1 border-beerus flex justify-between">
              <Button
                disabled={disabled_editing?(@current_user, @post)}
                class="edit-button"
                on_click="update_post_by_click"
              >Update post</Button>
              <Button
                disabled={disabled?(@current_user, @post)}
                class="delete-button"
                on_click="open_delete_modal"
                value={@post.id}
                type="button"
              >Delete post</Button>
              <Button class="close-button" on_click="close_update_drawer" type="button">Close details</Button>
            </div>
          </div>
        </Form>
      </Drawer.Panel>
    </Drawer>

    <Modal id="modal" on_close="close_modal" is_open={@post_modal} :if={@post_modal}>
      <Modal.Backdrop />
      <Modal.Panel>
        <div class="p-4 text-center border-b-2 border-beerus leading-7">
          <h3 class="text-moon-18 text-bulma font-medium">
            Are you sure that you want to delete this post?
          </h3>
          <br>
          <h4>
            <strong>
              Id:
            </strong>
            {@post_modal.id}
          </h4>
          <h4>
            <strong>
              Title:
            </strong>
            {@post_modal.title}
          </h4>
          <br>
        </div>
        <div class="p-2 border-t-1 border-beerus flex justify-between">
          <Button class="delete-button" on_click="approve_delete" value={@post_modal.id}>Yes, I am sure</Button>
          <Button class="close-button" on_click="close_modal">No, go back</Button>
        </div>
      </Modal.Panel>
    </Modal>
    <Dropdown id="dropdown_pagination" on_change="change_pagination" class="w-[10%] justify-center">
      <Dropdown.Options titles={[10, 5, 3]} />
      <Dropdown.Trigger :let={value: value}>
        <Chip class="flex justify-center w-full p-2 transition-colors border border-gray-300 rounded">
          <Icon name="text_bullets_list" />
          {value || "1-#{@limit} of"}</Chip>
      </Dropdown.Trigger>
    </Dropdown>
    <div class="w-full gap-4">
      <Table
        {=@sort}
        items={post <- CasinosAdmins.get_models_limit(assigns, assigns.posts)}
        sorting_click="handle_sorting_click"
        row_click="row_click"
      >
        <Column class="border border-gray" name="id" label="#" sortable>
          {post.id}
        </Column>
        <Column class="border border-gray" name="title" label="Title" sortable>
          {post.title}
        </Column>
        <Column class="border border-gray" name="body" label="Body" sortable>
          {post.body}
        </Column>
        <Column class="border border-gray" name="tags" label="Tags" sortable>
          {Blog.map_tags_to_string(post.tags)}
        </Column>
        <Column class="border border-gray" name="user_id" label="User name" sortable>
          {Accounts.get_user_name(post.user_id)}
        </Column>
        <Column class="border border-gray" name="published_at" label="Published at" sortable>
          {CasinosAdmins.get_right_datetime(post.published_at)}
        </Column>
        <Column class="border border-gray" name="inserted_at" label="Inserted at" sortable>
          {CasinosAdmins.get_right_datetime(post.inserted_at)}
        </Column>
        <Column class="border border-gray" name="updated_at" label="Updated at" sortable>
          {CasinosAdmins.get_right_datetime(post.updated_at)}
        </Column>
        <Column class="border border-gray" name="picture" label="Image">
          {#if post.picture}
            <img src={post.picture.path} class="w-16 h-12 object-cover">
          {#else}
            <span>No image</span>
          {/if}
        </Column>
        <Column name="publish" label="Publish post" sortable class="w-15 flex justify-center">
          <Button
            disabled={disabled?(@current_user, post)}
            value={post.id}
            on_click="publish_post"
            class="bg-transparent"
          >
            {#if post.published_at}
              <Icon name="generic_close" class="text-moon-48 text-chichi" />
            {#else}
              <Icon name="generic_plus" class="text-moon-48 text-roshi" />
            {/if}
          </Button>
        </Column>
      </Table>
    </div>

    <Pagination
      id="with_buttons"
      total_pages={max(CasinosAdmins.page_count(Enum.count(@posts), @limit), 1)}
      value={@current_page}
      on_change="handle_paging_click"
    >
      <Pagination.PrevButton class="border-none">
        <ControlsChevronLeft class="text-moon-24 rtl:rotate-180" />
      </Pagination.PrevButton>
      <Pagination.Pages selected_bg_color="bg-beerus text-trunks" />
      <Pagination.NextButton class="border-none">
        <ControlsChevronRight class="text-moon-24 rtl:rotate-180" />
      </Pagination.NextButton>
    </Pagination>
    """
  end
end
