defmodule MySuperAppWeb.HomeLive do
  use MySuperAppWeb, :surface_live_view
  import Surface

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~F"""
    <div class="flex flex-wrap justify-center items-center h-full gap-4">
      <a
        href="/admin"
        class="flex items-center justify-center bg-bulma p-3 w-[15%] rounded-lg text-white font-semibold
      shadow-md hover:bg-popo-dark transition duration-300 ease-in-out transform hover:scale-105"
      >
        admin page
      </a>
      <a
        href="/users"
        class="flex items-center justify-center bg-bulma p-3 w-[15%] rounded-lg text-white font-semibold
      shadow-md hover:bg-popo-dark transition duration-300 ease-in-out transform hover:scale-105"
      >
        user page
      </a>
      <a
        href="/tabs"
        class="flex items-center justify-center bg-bulma p-3 w-[15%] rounded-lg text-white font-semibold
      shadow-md hover:bg-popo-dark transition duration-300 ease-in-out transform hover:scale-105"
      >
        tabs
      </a>
      <a
        href="/acc"
        class="flex items-center justify-center bg-bulma p-3 w-[15%] rounded-lg text-white font-semibold
      shadow-md hover:bg-popo-dark transition duration-300 ease-in-out transform hover:scale-105"
      >
        acc
      </a>
      <a
        href="/menu"
        class="flex items-center justify-center bg-bulma p-3 w-[15%] rounded-lg text-white font-semibold
      shadow-md hover:bg-popo-dark transition duration-300 ease-in-out transform hover:scale-105"
      >
        menu
      </a>
      <a
        href="/form"
        class="flex items-center justify-center bg-bulma p-3 w-[15%] rounded-lg text-white font-semibold
      shadow-md hover:bg-popo-dark transition duration-300 ease-in-out transform hover:scale-105"
      >
        form
      </a>
    </div>
    """
  end
end
