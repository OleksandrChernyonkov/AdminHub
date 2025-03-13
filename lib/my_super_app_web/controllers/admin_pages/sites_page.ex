defmodule MySuperAppWeb.SitesPage do
  import Surface
  use MySuperAppWeb, :admin_surface_live_view
  alias Moon.Design.{Button, Search, Table, Modal, Drawer, Form, Pagination, Dropdown, Chip}
  alias Moon.Design.Table.Column
  alias Moon.Icon
  alias Moon.Design.Form.{Input, Field}
  alias MySuperApp.{CasinosAdmins, Site, Accounts}
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  @moduledoc """
  Module for rendering admin page
  """
  def mount(_params, session, socket) do
    form =
      %Site{}
      |> Site.changeset(%{})
      |> to_form()

    current_user = Accounts.get_user_by_session_token(session["user_token"])

    {:ok,
     assign(socket,
       sites: CasinosAdmins.get_all_sites(),
       before_datetime_sites: CasinosAdmins.get_all_sites(),
       site: nil,
       add_site_drawer_active: false,
       form: form,
       datetime_form: clear_datetime_form(),
       changeset: Site.changeset(%Site{}, %{}),
       total_pages: CasinosAdmins.page_count(Enum.count(CasinosAdmins.get_all_sites()), 10),
       filter: "",
       current_page: 1,
       sort: [name: "ASC"],
       limit: 10,
       current_user: current_user,
       operator_id: current_user.operator_id,
       site_modal: nil,
       start_datetime: "2024-01-01T00:00",
       end_datetime: "2024-12-31T23:59"
     )}
  end

  def handle_event("open_add_site_drawer", _, socket) do
    Drawer.open("add_site_drawer")

    {:noreply,
     assign(socket,
       add_site_drawer_active: true,
       form: to_form(Site.changeset(%Site{}, %{}))
     )}
  end

  def handle_event("add_validate", %{"site" => params}, socket) do
    form =
      %Site{}
      |> Site.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("add_site", %{"site" => site_params}, socket) do
    site_params = Map.put(site_params, "operator_id", socket.assigns.operator_id)

    case CasinosAdmins.create_site(site_params) do
      {:ok, site} ->
        Drawer.close("add_site_drawer")

        {:noreply,
         socket
         |> put_flash(:info, "Site created!")
         |> assign(
           sites: CasinosAdmins.get_all_sites(),
           before_datetime_sites: CasinosAdmins.get_all_sites(),
           selected: site.id,
           add_site_drawer_active: false
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket |> put_flash(:error, "Failed to create site!"),
           add_site_drawer_active: false
         )}
    end
  end

  def handle_event("close_drawer_by_click", _, socket) do
    Drawer.close("add_site_drawer")
    {:noreply, assign(socket, add_site_drawer_active: false)}
  end

  def handle_event("close_add_site_drawer", _, socket) do
    {:noreply, assign(socket, form: to_form(Site.changeset(%Site{}, %{})))}
  end

  def handle_event("change_filter", %{"value" => filter}, socket) do
    sites =
      CasinosAdmins.get_filtered_sites(filter)
      |> Enum.map(&Map.from_struct/1)

    {:noreply, assign(socket, filter: filter, sites: sites, before_datetime_sites: sites)}
  end

  def handle_event("change_pagination", %{"value" => limit}, socket) do
    total_pages = CasinosAdmins.page_count(Enum.count(socket.assigns.sites), socket.assigns.limit)

    {:noreply, assign(socket, limit: String.to_integer(limit), total_pages: total_pages)}
  end

  def handle_event("change_status", %{"value" => site_id}, socket) do
    status = if CasinosAdmins.get_site(site_id).status == :ACTIVE, do: :STOPPED, else: :ACTIVE
    CasinosAdmins.update_site(site_id, %{status: status})
    sites = CasinosAdmins.get_all_sites()

    {:noreply, assign(socket, sites: sites, before_datetime_sites: sites)}
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(current_page: current_page)}
  end

  def handle_event(
        "handle_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    sites = CasinosAdmins.sort_list(socket.assigns.sites, String.to_atom(sort_key), sort_dir)

    {:noreply,
     socket |> assign(sort: ["#{sort_key}": sort_dir], sites: sites, before_datetime_sites: sites)}
  end

  def handle_event("open_delete_modal", %{"value" => site_id}, socket) do
    Modal.open("modal")
    site_modal = CasinosAdmins.get_site(String.to_integer(site_id))
    {:noreply, assign(socket, site_modal: site_modal)}
  end

  def handle_event("approve_delete", %{"value" => site_id}, socket) do
    Modal.close("modal")
    CasinosAdmins.delete_site(String.to_integer(site_id))

    new_page =
      if rem(Enum.count(CasinosAdmins.get_all_sites()), socket.assigns.limit) == 0 and
           socket.assigns.current_page ==
             CasinosAdmins.page_count(
               Enum.count(CasinosAdmins.get_all_sites()),
               socket.assigns.limit
             ) + 1 do
        socket.assigns.current_page - 1
      else
        socket.assigns.current_page
      end

    {:noreply,
     assign(
       socket |> put_flash(:info, "site deleted!"),
       sites: CasinosAdmins.get_all_sites(),
       before_datetime_sites: CasinosAdmins.get_all_sites(),
       current_page: new_page
     )}
  end

  def handle_event("close_modal", _, socket) do
    Modal.close("modal")
    {:noreply, assign(socket, site_modal: nil)}
  end

  def handle_event(
        "filter_by_datetime",
        %{"start_datetime" => start_datetime, "end_datetime" => end_datetime},
        socket
      ) do
    filtered_sites =
      CasinosAdmins.get_filtered_sites_by_datetime(
        socket.assigns.before_datetime_sites,
        start_datetime,
        end_datetime
      )

    {:noreply,
     assign(socket,
       sites: filtered_sites,
       datetime_form: %{
         socket.assigns.datetime_form
         | source: %{"start_datetime" => start_datetime, "end_datetime" => end_datetime},
           params: %{"start_datetime" => start_datetime, "end_datetime" => end_datetime}
       }
     )}
  end

  def handle_event("clear", _, socket) do
    {:noreply,
     assign(socket,
       filter: "",
       sites: CasinosAdmins.get_all_sites(),
       before_datetime_sites: CasinosAdmins.get_all_sites(),
       datetime_form: clear_datetime_form()
     )}
  end

  def disabled?(current_user) do
    role_id = current_user.role_id
    permission_id = CasinosAdmins.get_role(role_id).permission_id

    case permission_id do
      4 -> false
      _ -> true
    end
  end

  def clear_datetime_form() do
    %{
      "start_datetime" => "",
      "end_datetime" => ""
    }
    |> to_form()
  end

  def render(assigns) do
    ~F"""
    <div class="flex flex-col w-full gap-4 mb-2">
      <Form change="filter_by_datetime" for={@datetime_form}>
        <div class="flex flex-col lg:flex-row justify-around items-end w-full gap-4">
          <Input type="datetime-local" field={:start_datetime} id="start_datetime" />
          <Input type="datetime-local" field={:end_datetime} id="end_datetime" />
        </div>
      </Form>
    </div>

    <div class="flex justify-between">
      <Search
        id="default-search"
        {=@filter}
        on_keyup="change_filter"
        options={[]}
        class="pb-3 w-[90%]"
        prompt="Search by id, brand or operator name"
      >
        <Dropdown id="1" disabled>
          <Dropdown.Trigger disabled />
        </Dropdown></Search>
      <Button class="close-button justify-right" on_click="clear">Clear all</Button>
    </div>
    <div class="justify-left flex gap-2 mb-3">
      <Dropdown id="dropdown_pagination" on_change="change_pagination" class="w-[10%] justify-center">
        <Dropdown.Options titles={[10, 5, 3]} />
        <Dropdown.Trigger :let={value: value}>
          <Chip class="flex w-full p-2 transition-colors border border-gray-200 rounded-md">
            <Icon name="text_bullets_list" />
            {value || "1-#{@limit} of"}</Chip>
        </Dropdown.Trigger>
      </Dropdown>
      <div class="flex h-full gap-2">
        <Button
          disabled={disabled?(@current_user)}
          class="add-button w-{30%}"
          on_click="open_add_site_drawer"
          value=""
        >
          Add site config</Button>
      </div>
    </div>
    <Drawer id="add_site_drawer" is_open={@add_site_drawer_active} on_close="close_add_site_drawer">
      <Drawer.Panel>
        <Form for={@form} change="add_validate" submit="add_site">
          <div class="mx-4">
            <br>
            <div class="text-2xl font-bold text-center mt-2 mb-2">
              Input new site`s name
            </div>
            <Field field={:brand} class="text-moon-30 font-medium">
              <Input class="text-center font-normal" placeholder="Name" />
            </Field>
            <div class="text-2xl font-bold text-center mt-2 mb-2">
              Operator`s name
            </div>
            <Field field={:operator_id} class="text-moon-30 font-medium">
              <Input
                class="text-center font-normal"
                disabled
                placeholder={CasinosAdmins.get_operator_name(@operator_id)}
              />
            </Field>
            <br>
            <div class="p-2 border-t-1 border-beerus flex justify-between">
              <Button class="add-button" type="submit">Add new site</Button>
              <Button class="close-button" on_click="close_drawer_by_click" type="button">Close window</Button>
            </div>
          </div>
        </Form>
      </Drawer.Panel>
    </Drawer>
    <div class="w-full">
      <Table
        {=@sort}
        sorting_click="handle_sorting_click"
        items={site <- CasinosAdmins.get_models_limit(assigns, assigns.sites)}
      >
        <Column class="border border-gray" name="id" label="#" sortable>
          {site.id}
        </Column>
        <Column class="border border-gray" name="brand" label="Brand" sortable>
          {site.brand}
        </Column>
        <Column class="border border-gray" name="operator_id" label="Operator" sortable>
          {CasinosAdmins.get_operator_name(site.operator_id)}
        </Column>
        <Column class="border border-gray" name="status" label="Status" sortable>
          {site.status}
        </Column>
        <Column class="border border-gray" name="inserted_at" label="Inserted at" sortable>
          {CasinosAdmins.get_right_datetime(site.inserted_at)}
        </Column>
        <Column class="border border-gray" name="updated_at" label="Updated at" sortable>
          {CasinosAdmins.get_right_datetime(site.updated_at)}
        </Column>
        <Column class="border border-gray" name="id">
          <Button class="bg-transparent w-full" on_click="change_status" type="button" value={site.id}>
            {#if CasinosAdmins.get_site(site.id).status == :STOPPED}
              <Icon name="media_play" class="text-moon-24 text-zeno fill-zeno/20" />
            {#else}
              <Icon name="media_pause" class="text-moon-24 fill-zeno" />
            {/if}
          </Button>
        </Column>
        <Column class="border border-gray">
          <Button class="bg-transparent w-full" on_click="open_delete_modal" value={site.id} type="button">
            <Icon name="generic_minus" class="text-moon-24 text-popo" />
          </Button>
        </Column>
      </Table>
    </div>
    <Pagination
      id="with_buttons"
      total_pages={max(1, CasinosAdmins.page_count(Enum.count(@sites), @limit))}
      value={@current_page}
      on_change="handle_paging_click"
    >
      <Pagination.PrevButton class="border-none">
        <ControlsChevronLeft class="text-moon-24 rtl:rotate-180" />
      </Pagination.PrevButton>
      <Pagination.Pages selected_bg_color="bg-beerus text-bulma" />
      <Pagination.NextButton class="border-none">
        <ControlsChevronRight class="text-moon-24 rtl:rotate-180" />
      </Pagination.NextButton>
    </Pagination>
    <Modal id="modal" on_close="close_modal" is_open={@site_modal} :if={@site_modal}>
      <Modal.Backdrop />
      <Modal.Panel>
        <div class="p-4 text-center border-b-2 border-beerus leading-7">
          <h3 class="text-moon-18 text-bulma font-medium">
            Are you sure that you want to delete this site?
          </h3>
          <br>
          <h4>
            <strong>
              Id:
            </strong>
            {@site_modal.id}
          </h4>
          <h4>
            <strong>
              Brand:
            </strong>
            {@site_modal.brand}
          </h4>
          <h4>
            <strong>
              Status:
            </strong>
            {@site_modal.status}
          </h4>
        </div>
        <div class="p-2 border-t-1 border-beerus flex justify-between">
          <Button class="delete-button" on_click="approve_delete" value={@site_modal.id}>Yes, I am sure</Button>
          <Button class="close-button" on_click="close_modal">No, go back</Button>
        </div>
      </Modal.Panel>
    </Modal>
    """
  end
end
