defmodule MySuperApp.CasinosAdmins do
  alias NaiveDateTime
  alias MySuperApp.{Operator, Role, Repo, Site, Permission}
  import Ecto.Query

  @moduledoc false
  def create_operator(attrs \\ %{}) do
    %Operator{}
    |> Operator.changeset(attrs)
    |> Repo.insert()
  end

  def create_permission(attrs \\ %{}) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
  end

  def create_site(attrs \\ %{}) do
    %Site{}
    |> Site.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, role} -> {:ok, Repo.preload(role, [:operator])}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, role} -> {:ok, Repo.preload(role, [:permission, :operator])}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def get_role(id) do
    Role
    |> Repo.get(id)
    |> Repo.preload([:permission, :operator])
  end

  def get_site(id) do
    Site
    |> Repo.get(id)
    |> Repo.preload([:operator])
  end

  def get_sites_by_date(date_string) do
    date = get_date_from_string(date_string)

    from(s in Site, where: fragment("date(?) = ?", s.inserted_at, ^date))
    |> Repo.all()
    |> Repo.preload([:operator])
  end

  def get_sites_by_period(start_date, end_date) do
    from(s in Site, where: s.inserted_at >= ^start_date and s.inserted_at <= ^end_date)
    |> Repo.all()
    |> Repo.preload([:operator])
  end

  def get_sites_by_operator(operator_name) do
    from(s in Site,
      join: o in assoc(s, :operator),
      where: o.name == ^operator_name
    )
    |> Repo.all()
    |> Repo.preload([:operator])
  end

  def get_operator(id) do
    Repo.get(Operator, id)
  end

  def get_all_sites() do
    query = from(s in Site, order_by: [asc: s.id], select: s)

    Repo.all(query)
    |> Enum.map(&Map.from_struct/1)
  end

  def get_all_sites_for_api() do
    Repo.all(from(s in Site, order_by: [asc: s.id], select: s))
    |> Repo.preload([:operator])
  end

  def get_filtered_sites(filter) do
    sites =
      from(s in Site,
        preload: [:operator]
      )
      |> Repo.all()

    id_filter =
      case Integer.parse(filter) do
        {id, ""} -> id
        _ -> nil
      end

    Enum.filter(sites, fn site ->
      String.contains?(site.brand, filter) or
        (id_filter != nil and site.id == id_filter) or
        (site.operator && String.contains?(site.operator.name, filter))
    end)
  end

  def get_filtered_sites_by_datetime(sites, start_datetime, end_datetime) do
    start_datetime = get_valid_start_datetime(start_datetime)
    end_datetime = get_valid_end_datetime(end_datetime)

    Enum.filter(sites, fn site ->
      NaiveDateTime.compare(site.inserted_at, start_datetime) != :lt and
        NaiveDateTime.compare(site.inserted_at, end_datetime) != :gt
    end)
  end

  def get_filtered_roles(filter) do
    from(r in Role, where: ilike(r.name, ^"%#{filter}%"))
    |> Repo.all()
  end

  def get_all_roles() do
    query = from r in Role, order_by: [desc: r.updated_at], select: r

    Repo.all(query)
    |> Enum.map(&Map.from_struct/1)
  end

  def get_all_roles_for_api() do
    Repo.all(from r in Role, order_by: [desc: r.updated_at], select: r)
    |> Repo.preload([:operator, :permission])
  end

  def get_all_operators() do
    query = from o in Operator, order_by: [desc: o.updated_at], select: o

    Repo.all(query)
    |> Enum.map(&Map.from_struct/1)
  end

  def get_operators_names() do
    Operator
    |> select([o], o.name)
    |> Repo.all()
  end

  def get_roles_names(%Role{} = role) do
    if is_nil(role.operator_id) do
      Role
      |> where([r], r.permission_id < ^role.permission_id or r.id == 1)
      |> select([r], r.name)
      |> Repo.all()
    else
      Role
      |> where(
        [r],
        (r.permission_id < ^role.permission_id and r.operator_id == ^role.operator_id) or
          r.id == 1
      )
      |> select([r], r.name)
      |> Repo.all()
    end
  end

  def get_roles_names("all operators") do
    Role
    |> select([r], r.name)
    |> Repo.all()
  end

  def get_roles_names(operator_name) when is_binary(operator_name) do
    operator = get_operator_by_name(operator_name)

    Role
    |> where([r], r.operator_id == ^operator.id)
    |> select([r], r.name)
    |> Repo.all()
  end

  def get_operator_name(nil) do
    "-"
  end

  def get_operator_name(id) do
    operator = Repo.get(Operator, id)
    Map.get(operator, :name)
  end

  def get_role_name(nil) do
    "-"
  end

  def get_role_name(id) do
    role = Repo.get(Role, id)
    Map.get(role, :name)
  end

  def get_role_id_by_name(role_name) do
    Repo.one(from(r in Role, where: r.name == ^role_name, select: r.id))
  end

  def get_role_by_name(role_name) do
    Repo.get_by(Role, name: role_name)
    |> Repo.preload([:permission, :operator])
  end

  def get_operator_by_name(operator_name) do
    Repo.one(from(o in Operator, where: o.name == ^operator_name))
  end

  def get_permission_name(id) do
    permission = Repo.get(Permission, id)
    Map.get(permission, :name)
  end

  def get_models_limit(%{current_page: current_page, limit: limit}, list) do
    offset = (current_page - 1) * limit

    list
    |> Enum.slice(offset..(offset + limit - 1))
  end

  def update_role(id, attrs \\ %{}) do
    case Repo.get(Role, id) do
      %Role{} = role ->
        role
        |> Role.changeset(attrs)
        |> Repo.update()
        |> case do
          {:ok, updated_role} -> {:ok, Repo.preload(updated_role, [:permission, :operator])}
          {:error, changeset} -> {:error, changeset}
        end

      nil ->
        {:error, :not_found}
    end
  end

  def update_site(site_id, attrs \\ %{}) do
    case Repo.get(Site, site_id) do
      %Site{} = site ->
        site
        |> Site.changeset(attrs)
        |> Repo.update()
        |> case do
          {:ok, updated_site} -> {:ok, Repo.preload(updated_site, [:operator])}
          {:error, changeset} -> {:error, changeset}
        end

      nil ->
        {:error, :not_found}
    end
  end

  def delete_role(role_id) do
    case Repo.get(Role, role_id) do
      %Role{} = role ->
        Repo.delete(role)

      nil ->
        {:error, "Role not found"}
    end
  end

  def delete_site(site_id) do
    case Repo.get(Site, site_id) do
      %Site{} = site ->
        Repo.delete(site)

      nil ->
        {:error, "Site not found"}
    end
  end

  def get_right_datetime(nil) do
    "Not published"
  end

  def get_right_datetime(naive_datetime) do
    "#{NaiveDateTime.to_date(naive_datetime)} #{NaiveDateTime.to_time(naive_datetime)}"
  end

  def sort_list(list, column, dir) do
    case dir do
      "ASC" ->
        list
        |> Enum.sort_by(&[&1[column]], :asc)

      "DESC" ->
        list
        |> Enum.sort_by(&[&1[column]], :desc)

      _ ->
        list
    end
  end

  def page_count(total_count, limit) do
    ceil(total_count / limit)
  end

  def get_valid_start_datetime("") do
    DateTime.from_iso8601("2024-01-01T00:00:00Z")
    |> elem(1)
    |> DateTime.to_naive()
  end

  def get_valid_start_datetime(non_valid_start_datetime) do
    DateTime.from_iso8601(non_valid_start_datetime <> ":00Z")
    |> elem(1)
    |> DateTime.to_naive()
  end

  def get_valid_end_datetime("") do
    DateTime.from_iso8601("2024-12-31T23:59:00Z")
    |> elem(1)
    |> DateTime.to_naive()
  end

  def get_valid_end_datetime(non_valid_end_datetime) do
    DateTime.from_iso8601(non_valid_end_datetime <> ":00Z")
    |> elem(1)
    |> DateTime.to_naive()
  end

  def string_keys_to_atom_keys(params) do
    params
    |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
    |> Enum.into(%{})
  end

  defp get_date_from_string(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end
end
