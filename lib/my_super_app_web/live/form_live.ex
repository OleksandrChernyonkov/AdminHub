defmodule MySuperAppWeb.FormLive do
  use MySuperAppWeb, :live_view

  alias MySuperApp.{User, Accounts}

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.form for={@form} phx-change="validate" phx-submit="save">
      <.input type="text" field={@form[:username]} />
      <.input type="email" field={@form[:email]} />
      <button class="button_class">Save</button>
    </.form>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(User.changeset(%User{}, %{})))}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "user #{user_params["username"]} created")
         |> redirect(to: ~p"/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
