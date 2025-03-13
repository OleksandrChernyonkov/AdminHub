defmodule MySuperAppWeb.SiteJSON do
  alias MySuperApp.Site

  @doc """
  Renders a list of sites.
  """
  def index(%{sites: sites}) do
    %{data: for(site <- sites, do: data(site))}
  end

  @doc """
  Renders a single site.
  """
  def show(%{site: site}) do
    %{data: data(site)}
  end

  @doc """
  Prepares site data for rendering.
  """
  def data(%Site{} = site) do
    %{
      id: site.id,
      brand: site.brand,
      status: site.status,
      inserted_at: site.inserted_at,
      updated_at: site.updated_at,
      operator: site.operator
    }
  end
end
