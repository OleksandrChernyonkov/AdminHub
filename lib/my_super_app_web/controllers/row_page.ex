defmodule MySuperAppWeb.RowPage do
  alias MySuperApp.{RowProcessor, Accounts, CasinosAdmins}
  alias Moon.Design.{Form, Button, Table, Modal, Pagination}
  alias Moon.Design.Table.Column
  alias Moon.Design.Form.{Input, Field}
  alias Moon.Icon
  alias Moon.Icons.ControlsChevronRight
  alias Moon.Icons.ControlsChevronLeft
  use MySuperAppWeb, :surface_live_view

  @moduledoc """
  Module for rendering vocabulary app
  """
  def mount(_params, session, socket) do
    rows = RowProcessor.get_list()
    random_row = RowProcessor.get_random_row(rows)

    {:ok,
     assign(socket,
       rows: rows,
       current_user: Accounts.get_user_by_session_token(session["user_token"]),
       add_words_modal: false,
       random_row: random_row,
       original_word: RowProcessor.get_original_word("ENG/UKR", random_row),
       translated_word: "",
       translation_type: "ENG/UKR",
       current_page: 1,
       limit: 50,
       sort: [name: "ASC"],
       total_pages: CasinosAdmins.page_count(Enum.count(rows), 10),
       toggle_table_view: false,
       filter_form:
         RowProcessor.get_filter_form(rows)
         |> to_form()
     )}
  end

  def handle_event("open_add_words_modal", _params, socket) do
    {:noreply, assign(socket, add_words_modal: true)}
  end

  def handle_event("process_rows", %{"rows" => rows}, socket) do
    RowProcessor.process_rows(rows)
    {:noreply, assign(socket, add_words_modal: false, rows: RowProcessor.get_list())}
  end

  def handle_event("close_add_words_modal", _params, socket) do
    Modal.close("add_words_modal")
    {:noreply, assign(socket, add_words_modal: false)}
  end

  def handle_event("get_translation", _params, socket) do
    Modal.close("add_words_modal")

    {:noreply,
     assign(socket,
       translated_word:
         RowProcessor.get_translation(socket.assigns.translation_type, socket.assigns.random_row)
     )}
  end

  def handle_event("get_next_word", _params, socket) do
    Modal.close("add_words_modal")
    random_row = RowProcessor.get_random_row(socket.assigns.rows)

    {:noreply,
     assign(socket,
       original_word: RowProcessor.get_original_word(socket.assigns.translation_type, random_row),
       random_row: random_row,
       translated_word: ""
     )}
  end

  def handle_event("change_language", _params, socket) do
    Modal.close("add_words_modal")

    {:noreply,
     assign(socket,
       original_word:
         RowProcessor.get_translation(socket.assigns.translation_type, socket.assigns.random_row),
       translated_word:
         RowProcessor.get_original_word(
           socket.assigns.translation_type,
           socket.assigns.random_row
         ),
       translation_type: RowProcessor.change_type(socket.assigns.translation_type)
     )}
  end

  def handle_event("filter_by_id_range", %{"from_id" => from_id, "to_id" => to_id}, socket) do
    RowProcessor.get_list_by_id_range(from_id, to_id)

    {:noreply,
     assign(socket,
       rows: RowProcessor.get_list_by_id_range(from_id, to_id),
       filter_form: %{"from_id" => from_id, "to_id" => to_id} |> to_form()
     )}
  end

  def handle_event("remove_from_rows", _params, socket) do
    rows = RowProcessor.remove_row_from_rows(socket.assigns.rows, socket.assigns.random_row.id)
    random_row = RowProcessor.get_random_row(rows)

    {:noreply,
     assign(socket,
       rows: rows,
       random_row: random_row,
       original_word: RowProcessor.get_original_word(socket.assigns.translation_type, random_row),
       translated_word: ""
     )}
  end

  def handle_event("restart_rows", _params, socket) do
    rows = RowProcessor.get_list()

    {:noreply,
     assign(socket,
       rows: rows,
       filter_form:
         RowProcessor.get_filter_form(rows)
         |> to_form()
     )}
  end

  def handle_event("handle_paging_click", %{"value" => current_page}, socket) do
    current_page = String.to_integer(current_page)

    {:noreply,
     socket
     |> assign(
       current_page: current_page,
       users_10: CasinosAdmins.get_models_limit(socket.assigns, socket.assigns.rows)
     )}
  end

  def handle_event("change_toggle_table_view", _params, socket) do
    {:noreply,
     socket
     |> assign(toggle_table_view: !socket.assigns.toggle_table_view)}
  end

  defp disable_access(current_user) do
    !(current_user.email == "cayman_raw@ukr.net")
  end

  def render(assigns) do
    ~F"""
    <div class="flex flex-col items-center">
      <div class="flex justify-center items-center gap-10 mb-3">
        <Button
          class="add-button border-2 border-blue-500 hover:bg-blue-200 text-black font-bold p-2 rounded"
          disabled={disable_access(@current_user)}
          on_click="open_add_words_modal"
        >
          Add new words
        </Button>

        <div class="border-2 border-black rounded-lg bg-gray-100 shadow-lg">
          <Form for={@filter_form} change="filter_by_id_range" class="flex items-center gap-4 p-4">
            <span class="font-bold">from ID:</span>
            <Field field={:from_id}>
              <Input
                type="number"
                placeholder={@filter_form.params["from_id"]}
                class="w-20 p-2 border-2 border-gray-300 rounded text-center text-black text-xl focus:outline-none focus:ring focus:ring-blue-500"
              />
            </Field>

            <span class="font-bold">to ID:</span>
            <Field field={:to_id}>
              <Input
                type="number"
                placeholder={@filter_form.params["to_id"]}
                class="w-20 p-2 border-2 border-gray-300 rounded text-center text-black text-xl focus:outline-none focus:ring focus:ring-blue-500"
              />
            </Field>
            <Button
              on_click="restart_rows"
              class="close-button font-bold text-black border-2 border-black hover:bg-red-200"
            >
              <Icon class="text-3xl" name="arrows_update" />
            </Button>
          </Form>
        </div>

        <Button
          on_click="change_language"
          class="edit-button font-bold text-black border-2 border-black hover:bg-gray-200"
        >
          {@translation_type}
          <Icon class="text-3xl" name="arrows_refresh_round" />
        </Button>
      </div>

      <div class="w-3/4 p-4 text-center border-2 border-black rounded-lg shadow-lg">
        <div class="font-bold mb-4">Words in the selected list: {Enum.count(@rows)}.</div>
        <div class="bg-white p-4 rounded-lg shadow">
          <Input
            type="text"
            placeholder={@original_word}
            readonly
            class="w-full p-2 border-2 border-gray-300 rounded text-center font-bold text-black text-xl"
          />
        </div>
        <br>
        <div class="flex justify-center gap-4">
          <Button
            on_click="remove_from_rows"
            disabled={@rows == []}
            class="delete-button font-bold text-black border-2 border-black hover:bg-red-200"
          >
            <Icon class="text-3xl" name="generic_minus" />
          </Button>
          <Button
            on_click="get_next_word"
            class="edit-button font-bold text-black border-2 border-black hover:bg-blue-200"
          >
            Next word
          </Button>
          <Button
            on_click="get_translation"
            class="edit-button font-bold text-black border-2 border-black hover:bg-green-200"
          >
            <Icon class="text-3xl" name="controls_eye" />
          </Button>
        </div>
        <br>
        <div class="bg-white p-4 rounded-lg shadow">
          <Input
            type="text"
            placeholder={@translated_word}
            readonly
            class="w-full p-2 border-2 border-gray-300 rounded text-center font-bold text-black text-xl"
          />
        </div>
      </div>

      <br>
      <Button
        on_click="change_toggle_table_view"
        class="close-button font-bold text-black border-2 border-black hover:bg-green-200"
      >
        {#if @toggle_table_view}
          <Icon class="text-3xl" name="controls_chevron_up" />
          <span>Hide table with words</span>
          <Icon class="text-3xl" name="controls_chevron_up" />
        {#else}
          <Icon class="text-3xl" name="controls_chevron_down" />
          <span>Show table with words</span>
          <Icon class="text-3xl" name="controls_chevron_down" />
        {/if}
      </Button>
      <br>

      {#if @toggle_table_view and @rows != []}
        <Table
          items={row <- CasinosAdmins.get_models_limit(assigns, assigns.rows)}
          sorting_click="handle_sorting_click"
        >
          <Column class="border border-gray size-15" name="id" label="#">
            {row.id}
          </Column>
          <Column class="border border-gray size-35" name="eng_word" label="English">
            {row.eng_word}
          </Column>
          <Column class="border border-gray size-35" name="ukr_word" label="Ukrainian">
            {row.ukr_word}
          </Column>
          <Column class="border border-gray size-15" name="inserted_at" label="Created at">
            {CasinosAdmins.get_right_datetime(row.inserted_at)}
          </Column>
        </Table>
        <Pagination
          id="with_buttons"
          total_pages={max(1, CasinosAdmins.page_count(Enum.count(@rows), @limit))}
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
      {/if}

      <Modal
        id="add_words_modal"
        on_close="close_add_words_modal"
        is_open={@add_words_modal}
        :if={@add_words_modal}
      >
        <Modal.Backdrop />
        <Modal.Panel class="transition-transform transform bg-white rounded-lg shadow-lg">
          <form phx-submit="process_rows">
            <div class="p-4 text-center border-b-2 border-beerus leading-7">
              <textarea
                name="rows"
                class="w-full p-2 border border-gray-300 rounded"
                placeholder="Please enter the new rows with English words and their translations in the format: apple - яблуко."
                style="height: 200px"
              />
            </div>
            <div class="p-2 border-t-1 border-beerus flex justify-between">
              <Button class="add-button" type="submit">Add new words</Button>
              <Button class="close-button" on_click="close_add_words_modal">No, go back</Button>
            </div>
          </form>
        </Modal.Panel>
      </Modal>
    </div>
    """
  end
end
