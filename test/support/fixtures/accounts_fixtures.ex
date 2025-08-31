defmodule Eatfair.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Eatfair.Accounts` context.
  """

  import Ecto.Query

  alias Eatfair.Accounts
  alias Eatfair.Accounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    attrs = if is_list(attrs), do: Enum.into(attrs, %{}), else: attrs
    user = unconfirmed_user_fixture(attrs)

    # Update role if specified
    user =
      case attrs[:role] do
        nil ->
          user

        role when is_atom(role) ->
          changeset = Ecto.Changeset.change(user, %{role: Atom.to_string(role)})
          {:ok, updated_user} = Eatfair.Repo.update(changeset)
          updated_user

        role when is_binary(role) ->
          changeset = Ecto.Changeset.change(user, %{role: role})
          {:ok, updated_user} = Eatfair.Repo.update(changeset)
          updated_user
      end
    
    # Update name and phone_number if specified
    user =
      case Map.take(attrs, [:name, :phone_number]) do
        empty when map_size(empty) == 0 ->
          user
          
        updates ->
          changeset = Ecto.Changeset.change(user, updates)
          {:ok, updated_user} = Eatfair.Repo.update(changeset)
          updated_user
      end

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Accounts.login_user_by_magic_link(token)

    user
  end

  def confirmed_user_fixture(attrs \\ %{}) do
    default_address = Map.get(attrs, :default_address)
    attrs = Map.delete(attrs, :default_address)

    user = unconfirmed_user_fixture(attrs)

    # Manually confirm the user by setting confirmed_at
    changeset =
      user
      |> Ecto.Changeset.change(%{confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)})

    {:ok, user} = Eatfair.Repo.update(changeset)

    # Create default address if specified
    if default_address do
      {:ok, _address} =
        Accounts.create_address(%{
          "name" => "Home",
          "street_address" => default_address,
          # Default city
          "city" => "Amsterdam",
          # Default postal code
          "postal_code" => "1012 AB",
          "country" => "Netherlands",
          "is_default" => true,
          "user_id" => user.id
        })
    end

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Eatfair.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    Eatfair.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Eatfair.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  @doc """
  Generate address for a user.
  """
  def address_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()

    attrs =
      attrs
      |> Map.delete(:user)
      |> Enum.into(%{
        name: "Home",
        street_address: "Prinsengracht 100, Amsterdam",
        city: "Amsterdam",
        postal_code: "1015 EA",
        country: "Netherlands",
        is_default: true,
        user_id: user.id
      })

    {:ok, address} = Accounts.create_address(attrs)
    address
  end
end
