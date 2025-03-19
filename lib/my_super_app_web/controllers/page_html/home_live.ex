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
      shadow-md hover:bg-popo-dark hover:scale-105"
      >
        Admin page
      </a>
      <a
        href="/users"
        class="flex items-center justify-center bg-bulma p-3 w-[15%] rounded-lg text-white font-semibold
      shadow-md hover:bg-popo-dark hover:scale-105"
      >
        User page
      </a>

      <a
        href="/rows"
        class="flex items-center justify-center bg-bulma p-3 w-[15%] rounded-lg text-white font-semibold
      shadow-md hover:bg-popo-dark hover:scale-105"
      >
        Vocabulary app
      </a>
    </div>
    """
  end
end
