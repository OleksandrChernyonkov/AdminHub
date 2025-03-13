defmodule MySuperAppWeb.UsersPage do
  use MySuperAppWeb, :surface_live_view
  alias Moon.Design.{Button, Drawer, Form, Modal, Table, Pagination}
  alias Moon.Design.Table.Column
  alias MySuperApp.{User, Accounts, CasinosAdmins}
  alias Moon.Design.Form.{Input, Field}
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft

  @moduledoc false

  def mount(_params, _session, socket) do
    users = Accounts.get_all_users()
    total_pages = CasinosAdmins.page_count(Enum.count(users), 10)

    changeset = User.changeset(%User{}, %{})

    form =
      %User{}
      |> User.changeset(%{})
      |> to_form()

    {:ok,
     assign(socket,
       users: users,
       res_selected: nil,
       selected: nil,
       changeset: changeset,
       form: form,
       user: nil,
       user_modal: nil,
       user_updated: nil,
       add_user_drawer_active: false,
       current_page: 1,
       limit: 10,
       total_pages: total_pages
     )}
  end

  def handle_event("row_click", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("open_edit_user", %{"value" => id}, socket) do
    Drawer.open("edit_user_drawer")

    user =
      id
      |> String.to_integer()
      |> Accounts.get_user!()

    changeset = user |> User.changeset(%{})

    {:noreply,
     assign(socket,
       changeset: changeset,
       form: to_form(changeset),
       user_updated: user,
       res_selected: id
     )}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply,
     assign(socket,
       form: form,
       user_updated: %{username: params["username"], email: params["email"]}
     )}
  end

  def handle_event("edit", %{"user" => user_params}, socket) do
    Drawer.close("edit_user_drawer")

    case Accounts.update_user(socket.assigns.res_selected, user_params) do
      {:ok, _user} ->
        {:noreply,
         assign(
           socket |> put_flash(:info, "Updated!"),
           users: Accounts.get_all_users(),
           selected: socket.assigns.res_selected
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("on_close", _params, socket) do
    Drawer.close("edit_user_drawer")
    {:noreply, socket}
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
           socket.assigns.current_page == ceil(Enum.count(Accounts.get_all_users()) / 10) + 1 do
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
    Drawer.close("edit_user_drawer")
    {:noreply, socket}
  end

  def handle_event("open_add_user_drawer", _, socket) do
    Drawer.open("add_user_drawer")

    {:noreply,
     assign(socket, add_user_drawer_active: true, form: to_form(User.changeset(%User{}, %{})))}
  end

  def handle_event("add_validate", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("add_user", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        Drawer.close("add_user_drawer")

        {:noreply,
         socket
         |> put_flash(:info, "User created!")
         |> assign(
           users: Accounts.get_all_users(),
           selected: user.id,
           add_user_drawer_active: false
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket |> put_flash(:error, "Failed to create user!"),
           add_user_drawer_active: false
         )}
    end
  end

  def handle_event("close_window", _, socket) do
    Drawer.close("add_user_drawer")
    {:noreply, assign(socket, add_user_drawer_active: false)}
  end

  def handle_event("add_user_drawer_close", _, socket) do
    {:noreply, assign(socket, form: to_form(User.changeset(%User{}, %{})))}
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
end
