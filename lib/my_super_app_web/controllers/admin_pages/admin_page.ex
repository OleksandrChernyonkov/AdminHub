defmodule MySuperAppWeb.AdminPage do
  import Surface
  use MySuperAppWeb, :admin_surface_live_view
  alias Moon.Design.{Search, Button, Modal, Table, Pagination, Dropdown, Chip}
  alias Moon.Design.Table.Column
  alias Moon.Icon
  alias MySuperApp.{CasinosAdmins, Accounts}
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  @moduledoc """
  Module for rendering admin page
  """

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       users: Accounts.get_all_users(),
       user: nil,
       user_modal: nil,
       current_page: 1,
       limit: 10,
       filter: "",
       total_pages: CasinosAdmins.page_count(Enum.count(Accounts.get_all_users()), 10),
       sort: [name: "ASC"],
       user_modal_role: nil,
       choose_operator: "all operators",
       choose_role: "all roles",
       current_user: Accounts.get_user_by_session_token(session["user_token"])
     )}
  end

  def handle_event("open_delete_modal", %{"value" => user_id}, socket) do
    Modal.open("modal")
    user_modal = Accounts.get_user!(String.to_integer(user_id))
    {:noreply, assign(socket, user_modal: user_modal)}
  end

  def handle_event("approve_delete", %{"value" => user_id}, socket) do
    Modal.close("modal")
    id = String.to_integer(user_id)
    user = Accounts.get_user!(id)

    Accounts.delete_user(user)

    new_page =
      if rem(Enum.count(Accounts.get_all_users()), socket.assigns.limit) == 0 and
           socket.assigns.current_page ==
             CasinosAdmins.page_count(Enum.count(Accounts.get_all_users()), 10) + 1 do
        socket.assigns.current_page - 1
      else
        socket.assigns.current_page
      end

    {:noreply,
     assign(
       socket |> put_flash(:info, "User deleted!"),
       users: Accounts.get_all_users(),
       current_page: new_page
     )}
  end

  def handle_event("close_modal", _, socket) do
    Modal.close("modal")
    {:noreply, socket}
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(
       current_page: current_page,
       users_10: CasinosAdmins.get_models_limit(socket.assigns, socket.assigns.users)
     )}
  end

  def handle_event(
        "handle_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    users = CasinosAdmins.sort_list(socket.assigns.users, String.to_atom(sort_key), sort_dir)

    {:noreply, socket |> assign(sort: ["#{sort_key}": sort_dir], users: users)}
  end

  def handle_event("click_give_role", %{"value" => user_id}, socket) do
    user = Accounts.get_user!(user_id)
    Modal.open("modal_role")
    {:noreply, assign(socket, user_modal_role: user)}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    role = CasinosAdmins.get_role_by_name(socket.assigns.choose_role)

    operator = CasinosAdmins.get_operator_by_name(socket.assigns.choose_operator)

    users = Accounts.get_filtered_users(filter, operator, role)

    {:noreply, assign(socket, filter: filter, users: users)}
  end

  def handle_event("change_operator", %{"value" => "all operators"}, socket) do
    role = CasinosAdmins.get_role_by_name(socket.assigns.choose_role)
    users = Accounts.get_filtered_users(socket.assigns.filter, nil, role)
    Modal.close("modal")

    {:noreply,
     assign(socket, users: users, choose_role: "all roles", choose_operator: "all operators")}
  end

  def handle_event("change_operator", %{"value" => operator_name}, socket) do
    role = CasinosAdmins.get_role_by_name(socket.assigns.choose_role)
    operator = CasinosAdmins.get_operator_by_name(operator_name)
    users = Accounts.get_filtered_users(socket.assigns.filter, operator, role)
    Modal.close("modal")
    {:noreply, assign(socket, users: users, choose_operator: operator_name)}
  end

  def handle_event("change_role", %{"value" => "all roles"}, socket) do
    operator = CasinosAdmins.get_operator_by_name(socket.assigns.choose_operator)
    users = Accounts.get_filtered_users(socket.assigns.filter, operator, nil)
    {:noreply, assign(socket, users: users, choose_role: "all roles")}
  end

  def handle_event("change_role", %{"value" => role_name}, socket) do
    role = CasinosAdmins.get_role_by_name(role_name)
    operator = CasinosAdmins.get_operator_by_name(socket.assigns.choose_operator)
    users = Accounts.get_filtered_users(socket.assigns.filter, operator, role)
    {:noreply, assign(socket, users: users, choose_role: role_name)}
  end

  def handle_event("set_role", %{"value" => role_name}, socket) do
    role_id = CasinosAdmins.get_role_id_by_name(role_name)

    socket.assigns.user_modal_role.role_id
    %{role_id: role_id}

    Accounts.update_user(socket.assigns.user_modal_role.id, %{role_id: role_id})

    users = Accounts.get_all_users()
    Modal.close("modal_role")
    {:noreply, assign(socket, users: users)}
  end

  def handle_event("close_modal_role", _, socket) do
    Modal.close("modal")
    {:noreply, assign(socket, user_modal_role: nil)}
  end

  def handle_event("clear", _, socket) do
    users = Accounts.get_filtered_users("", nil, nil)

    {:noreply,
     assign(socket,
       filter: "",
       choose_role: "all roles",
       choose_operator: "all operators",
       users: users
     )}
  end

  def handle_event("change_pagination", %{"value" => limit}, socket) do
    total_pages = CasinosAdmins.page_count(Enum.count(socket.assigns.users), socket.assigns.limit)

    {:noreply, assign(socket, limit: String.to_integer(limit), total_pages: total_pages)}
  end

  def disabled?(current_user, user) do
    cond do
      current_user.email == user.email ->
        true

      current_user.role.permission_id == 4 ->
        false

      current_user.role.permission_id >= 2 && user.operator_id == current_user.operator_id ->
        false

      true ->
        true
    end
  end

  def render(assigns) do
    ~F"""
    <div class="flex flex-row gap-2">
      <Dropdown id="operator_dropdown" on_change="change_operator" class="w-[20%]">
        <Dropdown.Options titles={["all operators"] ++ CasinosAdmins.get_operators_names()} />
        <Dropdown.Trigger :let={value: value}>
          <Chip class="w-full justify-center border border-trunks truncate">{value || @choose_operator}</Chip>
        </Dropdown.Trigger>
      </Dropdown>
      <Dropdown id="role_dropdown" on_change="change_role" class="w-[20%]">
        <Dropdown.Options titles={if @choose_operator == "all operators" do
          ["all roles"] ++ CasinosAdmins.get_roles_names(@choose_operator)
        else
          CasinosAdmins.get_roles_names(@choose_operator)
        end} />
        <Dropdown.Trigger :let={value: value}>
          <Chip class="w-full justify-center border border-trunks truncate">{value || @choose_role}</Chip>
        </Dropdown.Trigger>
      </Dropdown>
      <Search
        id="default-search"
        {=@filter}
        on_keyup="change_filter"
        options={[]}
        class="pb-3 w-[60%]"
        prompt="Search by username"
      >
        <Dropdown id="1" disabled>
          <Dropdown.Trigger disabled />
        </Dropdown></Search>
      <Button class="close-button" on_click="clear">Clear all</Button>
    </div>
    <Dropdown id="dropdown_pagination" on_change="change_pagination" class="w-[10%] justify-center">
      <Dropdown.Options titles={[10, 5, 3]} />
      <Dropdown.Trigger :let={value: value}>
        <Chip class="flex justify-center w-full p-2 transition-colors border border-gray-300 rounded">
          <Icon name="text_bullets_list" />
          {value || "1-#{@limit} of"}</Chip>
      </Dropdown.Trigger>
    </Dropdown>
    <Table
      {=@sort}
      items={user <- CasinosAdmins.get_models_limit(assigns, assigns.users)}
      sorting_click="handle_sorting_click"
    >
      <Column class="border border-gray" name="id" label="#" sortable>
        {user.id}
      </Column>
      <Column class="border border-gray" name="username" label="User name" sortable>
        {user.username}
      </Column>
      <Column class="border border-gray" name="operator_id" label="Operator" sortable>
        {CasinosAdmins.get_operator_name(user.operator_id)}
      </Column>
      <Column class="border border-gray" name="role_id" label="Role" sortable>
        {CasinosAdmins.get_role_name(user.role_id)}
      </Column>
      <Column class="border border-gray" name="inserted_at" label="Created at" sortable>
        {CasinosAdmins.get_right_datetime(user.inserted_at)}
      </Column>
      <Column class="border border-gray" name="updated_at" label="Updated at" sortable>
        {CasinosAdmins.get_right_datetime(user.updated_at)}
      </Column>
      <Column class="border border-gray">
        <Button
          disabled={disabled?(@current_user, user)}
          class="delete-button"
          on_click="open_delete_modal"
          value={user.id}
        >
          <Icon name="generic_minus" class="text-moon-24" />
          Delete
        </Button>
      </Column>
      <Column class="border border-gray">
        <Button
          disabled={disabled?(@current_user, user)}
          class="edit-button"
          on_click="click_give_role"
          value={user.id}
        >
          <Icon name="generic_edit" class="text-moon-24" />
          Give role
        </Button>
      </Column>
    </Table>
    <Pagination
      id="with_buttons"
      total_pages={max(1, CasinosAdmins.page_count(Enum.count(@users), @limit))}
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

    <Modal id="modal" on_close="close_modal" is_open={@user_modal} :if={@user_modal}>
      <Modal.Backdrop />
      <Modal.Panel>
        <div class="p-4 text-center border-b-2 border-beerus leading-7">
          <h3 class="text-moon-18 text-bulma font-medium">
            Are you sure that you want to delete this user?
          </h3>
          <br>
          <div class="text-gray-700 text-center">
            <p class="mb-2">
              <strong>Id:</strong> {@user_modal.id}
            </p>
            <p class="mb-2">
              <strong>Name:</strong> {@user_modal.username}
            </p>
            <p class="mb-2">
              <strong>Email:</strong> {@user_modal.email}
            </p>
          </div>
        </div>
        <div class="p-4 border-t-2 border-beerus flex justify-between">
          <Button class="delete-button" on_click="approve_delete" value={@user_modal.id}>
            Yes, I am sure
          </Button>
          <Button class="close-button" on_click="close_modal">
            No, go back
          </Button>
        </div>
      </Modal.Panel>
    </Modal>

    <Modal
      id="modal_role"
      on_close="close_modal_role"
      is_open={@user_modal_role}
      :if={@user_modal_role}
    >
      <Modal.Backdrop />
      <Modal.Panel>
        <div class="p-4 border-b-2 border-beerus justify-center">
          <h3 class="text-2xl font-semibold text-gray-800 mb-4 text-center">
            Choose relevant role for user
          </h3>
          <div class="text-gray-700 text-center">
            <p class="mb-2">
              <strong>Id:</strong> {@user_modal_role.id}
            </p>
            <p class="mb-2">
              <strong>User name:</strong> {@user_modal_role.username}
            </p>
            <p class="mb-2">
              <strong>Email:</strong> {@user_modal_role.email}
            </p>
            <Dropdown id="dropdown_role" on_change="set_role">
              <Dropdown.Options titles={CasinosAdmins.get_roles_names(@current_user.role)} />
              <Dropdown.Trigger :let={value: value}>
                <Chip class="w-full justify-center border border-trunks truncate">{value || CasinosAdmins.get_role_name(@user_modal_role.role_id)}</Chip>
              </Dropdown.Trigger>
            </Dropdown>
          </div>
        </div>

        <div class="p-2 border-t-1 border-beerus flex justify-center">
          <Button class="close-button" on_click="close_modal_role">Close window</Button>
        </div>
      </Modal.Panel>
    </Modal>
    """
  end
end
