defmodule MySuperAppWeb.Menu do
  use MySuperAppWeb, :surface_live_view

  alias Moon.Autolayouts.TopToDown
  alias Moon.Components.Heading
  alias Moon.Design.MenuItem
  alias Moon.Lego
  alias MySuperApp.{Repo, LeftMenu, RightMenu}

  data(expanded0, :boolean, default: false)
  data(expanded1, :boolean, default: true)
  data(expanded2, :boolean, default: false)
  data(left_menu, :any, default: [])
  data(right_menu, :any, default: [])

  @moduledoc """
  Module for menu rendering
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~F"""
    <TopToDown class="max-w-sm p-4 m-auto gap-4">
      <Heading size={24} class="text-center" is_regular>Menu</Heading>
      <div class="flex flex-col gap-2 w-56">
      </div>
    </TopToDown>
    <div class="flex justify-around w-full">
      <div class="w-56 bg-goku flex flex-col gap-2 rounded-moon-s-lg p-4">
        {#for menu <- @left_menu}
          {#if menu.title == "Tailwind"}
            <MenuItem role="switch" is_selected={@expanded0} title={menu.title} on_click="on_expand0" />
          {#else}
            <MenuItem>{menu.title}</MenuItem>
          {/if}
        {/for}
        {#if @expanded0}
          <MenuItem>
            <span class="w-6" />
            <Lego.Title>
              Accordion</Lego.Title>
          </MenuItem>
          <MenuItem>
            <span class="w-6" />
            <Lego.Title>
              Avatar</Lego.Title>
          </MenuItem>
          <MenuItem>
            <span class="w-6" />
            <Lego.Title>
              Breadcrumb</Lego.Title>
          </MenuItem>
          <MenuItem>
            <span class="w-6" />
            <Lego.Title>
              Button</Lego.Title>
          </MenuItem>
          <MenuItem>
            <span class="w-6" />
            <Lego.Title>
              Checkbox</Lego.Title>
          </MenuItem>
        {/if}
      </div>
      <div class="w-56 bg-goku flex flex-col gap-2 rounded-moon-s-lg p-4">
        {#for menu <- @right_menu}
          <MenuItem>{menu.title}</MenuItem>
        {/for}
      </div>
    </div>
    """
  end

  def handle_event("on_expand0" <> _number, params, socket) do
    {:noreply, assign(socket, expanded0: Map.get(params, "is-selected") |> convert!)}
  end

  def handle_event("on_expand1" <> _number, params, socket) do
    {:noreply, assign(socket, expanded1: Map.get(params, "is-selected") |> convert!)}
  end

  def handle_event("on_expand2" <> _number, params, socket) do
    {:noreply, assign(socket, expanded2: Map.get(params, "is-selected") |> convert!)}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, left_menu: LeftMenu |> Repo.all(), right_menu: RightMenu |> Repo.all())}
  end

  defp convert!("true"), do: true
  defp convert!("false"), do: false
end
