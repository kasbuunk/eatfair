defmodule Eatfair.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Eatfair.Repo

  alias Eatfair.Accounts.{User, UserToken, UserNotifier, Address}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Eatfair.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Eatfair.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    case UserToken.verify_magic_link_token_query(token) do
      {:ok, query} ->
        case Repo.one(query) do
          # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
          {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
            raise """
            magic link log in is not allowed for unconfirmed users with a password set!

            This cannot happen with the default implementation, which indicates that you
            might have adapted the code to a different use case. Please make sure to read the
            "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
            """

          {%User{confirmed_at: nil} = user, _token} ->
            user
            |> User.confirm_changeset()
            |> update_user_and_delete_all_tokens()

          {user, token} ->
            Repo.delete!(token)
            {:ok, {user, []}}

          nil ->
            {:error, :not_found}
        end

      :error ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Address management

  @doc """
  Returns the list of addresses for a user.

  ## Examples

      iex> list_user_addresses(user_id)
      [%Address{}, ...]

  """
  def list_user_addresses(user_id) do
    Repo.all(
      from a in Address,
        where: a.user_id == ^user_id,
        order_by: [desc: a.is_default, asc: a.inserted_at]
    )
  end

  @doc """
  Gets a single address.

  Raises `Ecto.NoResultsError` if the Address does not exist.

  ## Examples

      iex> get_address!(123)
      %Address{}

      iex> get_address!(456)
      ** (Ecto.NoResultsError)

  """
  def get_address!(id), do: Repo.get!(Address, id)

  @doc """
  Creates an address.

  ## Examples

      iex> create_address(%{field: value})
      {:ok, %Address{}}

      iex> create_address(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_address(attrs \\ %{}) do
    # Geocode the address if we don't have coordinates
    attrs = maybe_geocode_address(attrs)

    result =
      %Address{}
      |> Address.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, address} ->
        # If this is set as default, unset other defaults for this user
        if address.is_default do
          unset_other_default_addresses(address.user_id, address.id)
        end

        {:ok, address}

      error ->
        error
    end
  end

  defp maybe_geocode_address(attrs) do
    # Only geocode if we don't have coordinates and we have an address
    if is_nil(attrs["latitude"]) && is_nil(attrs["longitude"]) && attrs["street_address"] do
      address_string = build_address_string(attrs)

      case Eatfair.GeoUtils.geocode_address(address_string) do
        {:ok, %{latitude: lat, longitude: lon}} ->
          attrs
          |> Map.put("latitude", Decimal.new(Float.to_string(lat)))
          |> Map.put("longitude", Decimal.new(Float.to_string(lon)))

        {:error, :not_found} ->
          # Try with just the city if full address doesn't work
          city_string = attrs["city"] || ""

          case Eatfair.GeoUtils.geocode_address(city_string) do
            {:ok, %{latitude: lat, longitude: lon}} ->
              attrs
              |> Map.put("latitude", Decimal.new(Float.to_string(lat)))
              |> Map.put("longitude", Decimal.new(Float.to_string(lon)))

            _ ->
              attrs
          end
      end
    else
      attrs
    end
  end

  defp build_address_string(attrs) do
    [attrs["street_address"], attrs["city"], attrs["country"]]
    |> Enum.filter(&(&1 && String.trim(&1) != ""))
    |> Enum.join(", ")
  end

  @doc """
  Updates an address.

  ## Examples

      iex> update_address(address, %{field: new_value})
      {:ok, %Address{}}

      iex> update_address(address, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an address.

  ## Examples

      iex> delete_address(address)
      {:ok, %Address{}}

      iex> delete_address(address)
      {:error, %Ecto.Changeset{}}

  """
  def delete_address(%Address{} = address) do
    Repo.delete(address)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking address changes.

  ## Examples

      iex> change_address(address)
      %Ecto.Changeset{data: %Address{}}

  """
  def change_address(%Address{} = address, attrs \\ %{}) do
    Address.changeset(address, attrs)
  end

  @doc """
  Sets an address as the default for a user.

  ## Examples

      iex> set_default_address(user_id, address_id)
      {:ok, %Address{}}

      iex> set_default_address(user_id, invalid_address_id)
      {:error, %Ecto.Changeset{}}

  """
  def set_default_address(user_id, address_id) do
    address = Repo.get!(Address, address_id)

    # Verify the address belongs to the user
    if address.user_id != user_id do
      {:error, :not_found}
    else
      Repo.transact(fn ->
        # First unset all other default addresses for this user
        Repo.update_all(
          from(a in Address, where: a.user_id == ^user_id and a.id != ^address_id),
          set: [is_default: false]
        )

        # Then set this address as default
        case Repo.update(Address.changeset(address, %{is_default: true})) do
          {:ok, updated_address} -> {:ok, updated_address}
          error -> error
        end
      end)
    end
  end

  defp unset_other_default_addresses(user_id, current_address_id) do
    Repo.update_all(
      from(a in Address, where: a.user_id == ^user_id and a.id != ^current_address_id),
      set: [is_default: false]
    )
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
