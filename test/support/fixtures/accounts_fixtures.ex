defmodule MySuperApp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MySuperApp.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    role = MySuperApp.Repo.insert!(%MySuperApp.Role{name: "default_role"})
    operator = MySuperApp.Repo.insert!(%MySuperApp.Operator{name: "default_operator"})

    attrs =
      attrs
      |> Enum.into(%{
        username: "default_user",
        email: unique_user_email(),
        password: valid_user_password(),
        role_id: role.id,
        operator_id: operator.id
      })

    case MySuperApp.Accounts.register_user(attrs) do
      {:ok, user} ->
        user

      {:error, _changeset} ->
        raise "Failed to register user with given attributes"
    end
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
