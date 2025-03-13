defmodule MySuperAppWeb.OperatorsPage do
  import Surface
  use MySuperAppWeb, :admin_surface_live_view
  alias Moon.Design.{Button, Table, Drawer, Form}
  alias Moon.Design.Table.Column
  alias Moon.Design.Form.{Input, Field}
  # alias Moon.Icon
  alias MySuperApp.{CasinosAdmins, Operator, Accounts}

  @moduledoc """
  Module for rendering admin page
  """

  def mount(_params, session, socket) do
    form =
      %Operator{}
      |> Operator.changeset(%{})
      |> to_form()

    {:ok,
     assign(socket,
       operators: CasinosAdmins.get_all_operators(),
       operator: nil,
       add_operator_drawer_active: false,
       form: form,
       changeset: Operator.changeset(%Operator{}, %{}),
       sort: [name: "ASC"],
       current_user: Accounts.get_user_by_session_token(session["user_token"])
     )}
  end

  def handle_event("open_add_operator_drawer", _, socket) do
    Drawer.open("add_operator_drawer")

    {:noreply,
     assign(socket,
       add_operator_drawer_active: true,
       form: to_form(Operator.changeset(%Operator{}, %{}))
     )}
  end

  def handle_event("add_validate", %{"operator" => params}, socket) do
    form =
      %Operator{}
      |> Operator.changeset(params)
      |> Map.put(:action, :insert)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("add_operator", %{"operator" => operator_params}, socket) do
    case CasinosAdmins.create_operator(operator_params) do
      {:ok, operator} ->
        Drawer.close("add_operator_drawer")

        {:noreply,
         socket
         |> put_flash(:info, "Operator created!")
         |> assign(
           operators: CasinosAdmins.get_all_operators(),
           selected: operator.id,
           add_operator_drawer_active: false
         )}

      {:error, _reason} ->
        {:noreply,
         assign(socket |> put_flash(:error, "Failed to create operator!"),
           add_operator_drawer_active: false
         )}
    end
  end

  def handle_event("close_drawer_by_click", _, socket) do
    Drawer.close("add_operator_drawer")
    {:noreply, assign(socket, add_operator_drawer_active: false)}
  end

  def handle_event("close_add_operator_drawer", _, socket) do
    {:noreply, assign(socket, form: to_form(Operator.changeset(%Operator{}, %{})))}
  end

  def handle_event(
        "handle_sorting_click",
        %{"sort-dir" => sort_dir, "sort-key" => sort_key},
        socket
      ) do
    operators =
      CasinosAdmins.sort_list(socket.assigns.operators, String.to_atom(sort_key), sort_dir)

    {:noreply, socket |> assign(sort: ["#{sort_key}": sort_dir], operators: operators)}
  end

  def render(assigns) do
    ~F"""
    <div class="flex justify-center items-center mb-3 h-full">
      <Button class="add-button" on_click="open_add_operator_drawer" value="">Add new operator</Button>
    </div>
    <Drawer
      id="add_operator_drawer"
      is_open={@add_operator_drawer_active}
      on_close="close_add_operator_drawer"
    >
      <Drawer.Panel>
        <Form for={@form} change="add_validate" submit="add_operator">
          <div class="mx-4">
            <br>
            <div class="text-2xl font-bold text-center mt-2 mb-2">
              Input new operator`s name
            </div>
            <Field field={:name} class="text-moon-30 font-medium">
              <Input class="text-center font-normal" placeholder="Name" />
            </Field>
            <br>
            <div class="p-2 border-t-1 border-beerus flex justify-between">
              <Button class="add-button" type="submit">Add new operator</Button>
              <Button class="close-button" on_click="close_drawer_by_click" type="button">Close window</Button>
            </div>
          </div>
        </Form>
      </Drawer.Panel>
    </Drawer>
    <div class="w-full mb-1 gap-4">
      <Table {=@sort} sorting_click="handle_sorting_click" items={operator <- @operators}>
        <Column class="border border-gray" name="id" label="#" sortable>
          {operator.id}
        </Column>
        <Column class="border border-gray" name="name" label="Operator name" sortable>
          {operator.name}
        </Column>
        <Column class="border border-gray" name="inserted_at" label="Inserted at" sortable>
          {CasinosAdmins.get_right_datetime(operator.inserted_at)}
        </Column>
        <Column class="border border-gray" name="updated_at" label="Updated at" sortable>
          {CasinosAdmins.get_right_datetime(operator.updated_at)}
        </Column>
      </Table>
    </div>
    """
  end
end
