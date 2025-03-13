defmodule MySuperAppWeb.RolesPage do
  import Surface
  use MySuperAppWeb, :admin_surface_live_view
  alias Moon.Design.{Button, Table, Drawer, Form, Modal, Pagination, Search, Dropdown, Chip}
  alias Moon.Design.Table.Column
  alias Moon.Design.Form.{Input, Field}
  alias Moon.Icon
  alias MySuperApp.{CasinosAdmins, Role, Accounts}
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  @moduledoc """
  Module for rendering admin page
  """

  def mount(_params, session, socket) do
    roles = CasinosAdmins.get_all_roles()

    form =
      %Role{}
      |> Role.changeset(%{})
      |> to_form()

    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     assign(socket,
       roles: roles,
       role: %Role{},
       operator_name: nil,
       add_role_drawer_active: false,
       form: form,
       changeset: Role.changeset(%Role{}, %{}),
       operator_id: current_user.operator_id,
       operator: CasinosAdmins.get_operator(current_user.operator_id),
       operator_modal: nil,
       selected: nil,
       update_selected: nil,
       role_modal: nil,
       current_page: 1,
       limit: 10,
       sort: [name: "ASC"],
       total_pages: CasinosAdmins.page_count(Enum.count(roles), 10),
       filter: "",
       current_user: current_user
     )}
  end

  def handle_event("open_add_role_drawer", _, socket) do
    Drawer.open("add_role_drawer")

    {:noreply,
     assign(socket,
       add_role_drawer_active: true,
       form: to_form(Role.changeset(%Role{}, %{}))
     )}
  end

  def handle_event("add_validate", %{"role" => params}, socket) do
    form =
      %Role{}
      |> Role.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("add_role", %{"role" => role_params}, socket) do
    role_params = Map.put(role_params, "operator_id", socket.assigns.operator_id)

    case CasinosAdmins.create_role(role_params) do
      {:ok, _role} ->
        Drawer.close("add_role_drawer")

        {:noreply,
         socket
         |> put_flash(:info, "role created!")
         |> assign(
           roles: CasinosAdmins.get_all_roles(),
           add_role_drawer_active: false
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket |> put_flash(:error, "Failed to create role!"),
           add_role_drawer_active: false
         )}
    end
  end

  def handle_event("close_add_drawer_by_click", _, socket) do
    Drawer.close("add_role_drawer")
    {:noreply, assign(socket, add_role_drawer_active: false)}
  end

  def handle_event("close_add_role_drawer", _, socket) do
    {:noreply, assign(socket, form: to_form(Role.changeset(%Role{}, %{})))}
  end

  def handle_event("row_click", %{"selected" => selected}, socket) do
    role = CasinosAdmins.get_role(selected)
    {:noreply, assign(socket, selected: selected, update_selected: selected, role: role)}
  end

  def handle_event("update_validate", %{"role" => params}, socket) do
    params = Map.put(params, "operator_id", socket.assigns.role.operator_id)

    form =
      %Role{}
      |> Role.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply,
     assign(socket,
       form: form,
       role: %{
         id: socket.assigns.selected,
         name: params["name"],
         operator_id: params["operator_id"]
       }
     )}
  end

  def handle_event("update_role_by_click", %{"value" => name}, socket) do
    Drawer.close("update_drawer")

    case CasinosAdmins.update_role(socket.assigns.selected, %{"name" => name}) do
      {:ok, _role} ->
        {:noreply,
         assign(
           socket |> put_flash(:info, "Updated!"),
           roles: CasinosAdmins.get_all_roles()
         )}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           roles: CasinosAdmins.get_all_roles(),
           changeset: changeset,
           update_selected: nil
         )}
    end
  end

  def handle_event("open_delete_modal", %{"value" => selected}, socket) do
    Modal.open("modal")
    role_modal = CasinosAdmins.get_role(String.to_integer(selected))
    {:noreply, assign(socket, role_modal: role_modal)}
  end

  def handle_event("close_update_drawer", _params, socket) do
    Drawer.close("update_drawer")
    {:noreply, assign(socket, update_selected: nil)}
  end

  def handle_event("close_update_drawer_on_close", _, socket) do
    {:noreply, assign(socket, update_selected: nil, form: to_form(Role.changeset(%Role{}, %{})))}
  end

  def handle_event("approve_delete", %{"value" => role_id}, socket) do
    Modal.close("modal")
    CasinosAdmins.delete_role(String.to_integer(role_id))

    new_page =
      if rem(Enum.count(CasinosAdmins.get_all_roles()), socket.assigns.limit) == 0 and
           socket.assigns.current_page ==
             CasinosAdmins.page_count(
               Enum.count(CasinosAdmins.get_all_roles()),
               socket.assigns.limit
             ) + 1 do
        socket.assigns.current_page - 1
      else
        socket.assigns.current_page
      end

    {:noreply,
     assign(
       socket |> put_flash(:info, "role deleted!"),
       role_modal: nil,
       roles: CasinosAdmins.get_all_roles(),
       current_page: new_page
     )}
  end

  def handle_event("close_modal", _, socket) do
    Modal.close("modal")
    {:noreply, assign(socket, role_modal: nil)}
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(
       current_page: current_page,
       roles_10: CasinosAdmins.get_models_limit(socket.assigns, socket.assigns.roles)
     )}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    roles =
      CasinosAdmins.get_filtered_roles(filter)
      |> Enum.map(&Map.from_struct/1)

    {:noreply, assign(socket, filter: filter, roles: roles)}
  end

  def handle_event("change_pagination", %{"value" => limit}, socket) do
    total_pages = CasinosAdmins.page_count(Enum.count(socket.assigns.roles), socket.assigns.limit)

    {:noreply, assign(socket, limit: String.to_integer(limit), total_pages: total_pages)}
  end

  def handle_event(
        "handle_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    roles = CasinosAdmins.sort_list(socket.assigns.roles, String.to_atom(sort_key), sort_dir)

    {:noreply, socket |> assign(sort: ["#{sort_key}": sort_dir], roles: roles)}
  end

  def disabled(current_user) do
    role_id = current_user.role_id
    permission_id = CasinosAdmins.get_role(role_id).permission_id

    case permission_id do
      2 -> true
      _ -> !current_user.operator_id
    end
  end

  def render(assigns) do
    ~F"""
    <div class="flex gap-2 justify-center items-center h-full pb-3">
      <Search
        id="default-search"
        {=@filter}
        on_keyup="change_filter"
        options={[]}
        class="w-[90%]"
        prompt="Search by role"
      >
        <Dropdown id="1" disabled>
          <Dropdown.Trigger disabled />
        </Dropdown></Search>
      <Button disabled={disabled(@current_user)} class="add-button" on_click="open_add_role_drawer">Add new role</Button>
    </div>
    <Drawer id="add_role_drawer" is_open={@add_role_drawer_active} on_close="close_add_role_drawer">
      <Drawer.Panel>
        <Form for={@form} change="add_validate" submit="add_role">
          <div class="mx-4">
            <Field field={:name}>
              <br>
              <div class="text-2xl font-bold text-center mt-2 mb-2">
                Input role`s name
              </div>
              <Input class="text-center font-normal" placeholder="Name" />
            </Field>
            <br>
            <Field field={:operator_id} class="text-moon-30 font-medium">
              <div class="text-2xl font-bold text-center mt-2 mb-2">
                Operator
              </div>
              <Input class="text-center" readonly placeholder={CasinosAdmins.get_operator_name(@operator_id)} />
            </Field>
            <br>
            <div class="p-2 border-t-1 border-beerus flex justify-between">
              <Button class="add-button" type="submit">Add new role</Button>
              <Button class="close-button" on_click="close_add_drawer_by_click" type="button">Close window</Button>
            </div>
          </div>
        </Form>
      </Drawer.Panel>
    </Drawer>

    <Drawer id="update_drawer" is_open={@update_selected} on_close="close_update_drawer_on_close">
      <Drawer.Panel>
        <Form for={@form} change="update_validate">
          <div class="mx-4">
            <Field field={:name} class="text-moon-30 font-medium mb-4">
              <br>
              <div class="text-2xl font-bold text-center mt-2 mb-2">
                Input new role`s name
              </div>
              <div>
                <Input placeholder="Name" value={@role.name} class="text-center" />
              </div>
            </Field>
            <Field field={:operator_id} class="text-moon-30 font-medium mb-4">
              <div class="text-2xl font-bold text-center mt-2 mb-2">
                Operator
              </div>
              <div>
                <Input
                  placeholder="Operator"
                  value={CasinosAdmins.get_operator_name(@role.operator_id)}
                  disabled
                  class="text-center"
                />
              </div>
            </Field>
            <div class="p-2 border-t-1 border-beerus flex justify-between">
              <Button class="edit-button" on_click="update_role_by_click" value={@role.name}>Update role</Button>
              <Button class="delete-button" on_click="open_delete_modal" value={@role.id} type="button">Delete role</Button>
              <Button class="close-button" on_click="close_update_drawer" type="button">Close details</Button>
            </div>
          </div>
        </Form>
      </Drawer.Panel>
    </Drawer>

    <Modal id="modal" on_close="close_modal" is_open={@role_modal} :if={@role_modal}>
      <Modal.Backdrop />
      <Modal.Panel>
        <div class="p-4 text-center border-b-2 border-beerus leading-7">
          <h3 class="text-moon-18 text-bulma font-medium">
            Are you sure that you want to delete this role?
          </h3>
          <br>
          <h4>
            <strong>
              Id:
            </strong>
            {@role_modal.id}
          </h4>
          <h4>
            <strong>
              Name:
            </strong>
            {@role_modal.name}
          </h4>
          <h4>
            <strong>
              Operator:
            </strong>
            {CasinosAdmins.get_operator_name(@role_modal.operator_id)}
          </h4>
          <br>
        </div>
        <div class="p-2 border-t-1 border-beerus flex justify-between">
          <Button class="delete-button" on_click="approve_delete" value={@role_modal.id}>Yes, I am sure</Button>
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
        items={role <- CasinosAdmins.get_models_limit(assigns, assigns.roles)}
        sorting_click="handle_sorting_click"
        row_click="row_click"
      >
        <Column class="border border-gray" name="id" label="#" sortable>
          {role.id}
        </Column>
        <Column class="border border-gray" name="name" label="Name" sortable>
          {role.name}
        </Column>
        <Column class="border border-gray" name="operator_id" label="Operator" sortable>
          {CasinosAdmins.get_operator_name(role.operator_id)}
        </Column>
        <Column class="border border-gray" name="inserted_at" label="Inserted at" sortable>
          {CasinosAdmins.get_right_datetime(role.inserted_at)}
        </Column>
        <Column class="border border-gray" name="updated_at" label="Updated at" sortable>
          {CasinosAdmins.get_right_datetime(role.updated_at)}
        </Column>
      </Table>
    </div>

    <Pagination
      id="with_buttons"
      total_pages={max(1, CasinosAdmins.page_count(Enum.count(@roles), @limit))}
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
