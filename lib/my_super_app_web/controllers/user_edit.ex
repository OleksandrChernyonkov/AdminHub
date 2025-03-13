defmodule MySuperAppWeb.UserEdit do
  use MySuperAppWeb, :surface_live_view
  alias Moon.Design.{Button, Form}
  alias Moon.Design.Form.{Input, Field}
  alias MySuperApp.{Accounts, User}

  @moduledoc false

  def render(assigns) do
    ~F"""
    <Form for={@changeset} change="validate" submit="edit">
      <Field field={:username} label="Input new username" class="text-moon-30 font-medium">
        <Input value={@changeset.params["username"]} placeholder="Username" />
      </Field>
      <Field field={:email} label="Input new email" class="text-moon-30 font-medium">
        <Input value={@changeset.params["email"]} placeholder="Email" />
      </Field>
      <Button type="submit">Save</Button>
    </Form>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    user = Accounts.get_user!(id)
    changeset = User.changeset(user, %{})
    {:ok, assign(socket, changeset: changeset, user: user)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = User.changeset(socket.assigns.user, user_params)
    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("edit", %{"user" => user_params}, socket) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully.")
         |> redirect(to: ~p"/users")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
