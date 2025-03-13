defmodule MySuperAppWeb.UserJSON do
  alias MySuperApp.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  @doc """
  Prepares user data for rendering.
  """
  def data(%User{} = user) do
    %{
      id: user.id,
      username: user.username,
      email: user.email,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at,
      operator_id: user.operator_id,
      role_id: user.role_id
    }
  end
end
