defmodule Eatfair.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Eatfair.Repo

  alias Eatfair.Accounts.{User, UserToken, UserNotifier, Address, EmailVerification}
  alias Eatfair.Orders

  ## Database getters

  @doc """
  Counts users based on optional filters for admin dashboard metrics.

  ## Options

    * `:active` - Count only confirmed users when true
    * `:since` - Count users created since given date
    * `:role` - Count users with specific role

  ## Examples

      iex> count_users()
      42

      iex> count_users(active: true)
      38

      iex> count_users(since: Date.utc_today())
      5

  """
  def count_users(opts \\ []) do
    query =
      User
      |> select([u], count(u.id))
      |> maybe_filter_active(opts[:active])
      |> maybe_filter_since(opts[:since])
      |> maybe_filter_role(opts[:role])

    Repo.one(query)
  end

  defp maybe_filter_active(query, true), do: where(query, [u], not is_nil(u.confirmed_at))
  defp maybe_filter_active(query, _), do: query

  defp maybe_filter_since(query, nil), do: query

  defp maybe_filter_since(query, date) do
    {:ok, datetime} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
    where(query, [u], u.inserted_at >= ^datetime)
  end

  defp maybe_filter_role(query, nil), do: query
  defp maybe_filter_role(query, role), do: where(query, [u], u.role == ^role)

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

  @doc """
  Registers a user with profile information (without requiring password).
  Used for creating accounts from verified email addresses.

  ## Examples

      iex> register_user_with_profile(%{email: "test@example.com", phone_number: "+31 6 12345678"})
      {:ok, %User{}}

      iex> register_user_with_profile(%{email: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def register_user_with_profile(attrs) do
    %User{}
    |> User.profile_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a soft account for anonymous orders.
  
  A soft account is an unconfirmed user with only an email address.
  This allows orders to always have a customer_id while still supporting
  the anonymous ordering flow.
  
  ## Examples
  
      iex> create_soft_account("user@example.com")
      {:ok, %User{}}
      
      iex> create_soft_account("invalid-email")
      {:error, %Ecto.Changeset{}}
      
  """
  def create_soft_account(email) when is_binary(email) do
    # Check if user already exists
    case get_user_by_email(email) do
      nil ->
        # Create new soft account
        %User{}
        |> User.email_changeset(%{email: email})
        |> Repo.insert()
        
      existing_user ->
        # Return existing user
        {:ok, existing_user}
    end
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

  ## Email verification functions
  
  @doc """
  Sends an email verification email to the given email address.
  Can be associated with an order or user for account creation flow.
  """
  def send_verification_email(email, opts \\  []) do
    order = opts[:order]
    user = opts[:user]
    
    # Clean up expired verifications for this email
    cleanup_expired_verifications(email)
    
    token = EmailVerification.generate_token()
    expires_at = DateTime.add(DateTime.utc_now(), 24 * 60 * 60)  # 24 hours
    
    verification_attrs = %{
      email: email,
      token: token,
      expires_at: expires_at,
      order_id: order && order.id,
      user_id: user && user.id
    }
    
    case create_email_verification(verification_attrs) do
      {:ok, verification} ->
        # Update order email status to pending if order is provided
        if order do
          Orders.update_order_email_status(order.id, "pending")
        end
        
        # Send verification email
        UserNotifier.deliver_email_verification_instructions(verification, order)
        {:ok, verification}
        
      error -> error
    end
  end
  
  @doc """
  Verifies an email address using the provided token.
  """
  def verify_email(token) when is_binary(token) do
    verification = get_verification_by_token(token)
    
    cond do
      is_nil(verification) ->
        {:error, :not_found}
        
      not EmailVerification.valid?(verification) ->
        {:error, :expired}
        
      EmailVerification.verified?(verification) ->
        {:error, :already_verified}
        
      true ->
        now = DateTime.utc_now()
        
        case update_email_verification(verification, %{verified_at: now}) do
          {:ok, verification} ->
            # Update associated order email status if exists
            if verification.order_id do
              Orders.update_order_email_status(verification.order_id, "verified")
            end
            
            # Broadcast verification success
            broadcast_email_verified(verification.email)
            
            {:ok, verification}
            
          error -> error
        end
    end
  end
  
  @doc """
  Creates a user account from an order after email verification.
  This supports the anonymous-to-authenticated user conversion flow.
  
  If a user with the email already exists (like a soft account), it will
  upgrade their profile with information from the order.
  """
  def create_account_from_order(order, params \\  %{}) do
    # Check if user already exists with this email
    if existing_user = get_user_by_email(order.customer_email) do
      # Upgrade existing user (likely a soft account) with profile information
      user_params = %{
        phone_number: order.customer_phone,
        confirmed_at: DateTime.utc_now()  # Auto-confirm since email was verified
      }
      |> Map.merge(params)
      
      Repo.transaction(fn ->
        # Update the existing user with profile information
        changeset = User.update_profile_changeset(existing_user, user_params)
        
        with {:ok, updated_user} <- Repo.update(changeset),
             {:ok, updated_order} <- Orders.associate_order_with_user(order.id, updated_user.id),
             {:ok, _address} <- maybe_create_address_from_order(updated_user, order) do
          {updated_user, updated_order}
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
      |> case do
        {:ok, {user, order}} -> {:ok, user, order}
        {:error, reason} -> {:error, reason}
      end
    else
      # Create new user account
      user_params = %{
        email: order.customer_email,
        phone_number: order.customer_phone,
        confirmed_at: DateTime.utc_now()  # Auto-confirm since email was verified
      }
      |> Map.merge(params)
      
      Repo.transaction(fn ->
        with {:ok, user} <- register_user_with_profile(user_params),
             {:ok, updated_order} <- Orders.associate_order_with_user(order.id, user.id),
             {:ok, _address} <- maybe_create_address_from_order(user, order) do
          {user, updated_order}
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
      |> case do
        {:ok, {user, order}} -> {:ok, user, order}
        {:error, reason} -> {:error, reason}
      end
    end
  end
  
  @doc """
  Gets an email verification by token.
  """
  def get_verification_by_token(token) when is_binary(token) do
    EmailVerification
    |> where([v], v.token == ^token)
    |> preload([:order, :user])
    |> Repo.one()
  end
  
  @doc """
  Creates an email verification record.
  """
  def create_email_verification(attrs \\  %{}) do
    %EmailVerification{}
    |> EmailVerification.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates an email verification record.
  """
  def update_email_verification(%EmailVerification{} = verification, attrs) do
    verification
    |> EmailVerification.changeset(attrs)
    |> Repo.update()
  end
  
  @doc """
  Lists email verifications for an email address (for debugging/admin).
  """
  def list_email_verifications(email) when is_binary(email) do
    EmailVerification
    |> where([v], v.email == ^email)
    |> order_by([v], desc: v.inserted_at)
    |> limit(10)
    |> Repo.all()
  end
  
  # Private helper functions for email verification
  
  defp cleanup_expired_verifications(email) do
    now = DateTime.utc_now()
    
    from(v in EmailVerification,
      where: v.email == ^email and v.expires_at < ^now and is_nil(v.verified_at)
    )
    |> Repo.delete_all()
  end
  
  defp maybe_create_address_from_order(user, order) do
    # Extract address components from delivery_address string
    # This is a simple implementation - in production, you might want
    # more sophisticated address parsing
    
    # For now, provide basic parsing for testing. The full address is in delivery_address
    # Try to extract city and postal code from the delivery address
    {street, city, postal_code} = parse_delivery_address(order.delivery_address)
    
    address_attrs = %{
      user_id: user.id,
      street_address: street,
      city: city,
      postal_code: postal_code,
      name: "From Order ##{order.id}",
      is_default: true
    }
    
    create_address(address_attrs)
  end
  
  # Simple address parsing - in production this would be more sophisticated
  defp parse_delivery_address(delivery_address) do
    # Handle format like "Street 123, 1000 AB City"
    parts = String.split(delivery_address, ",")
    
    case parts do
      [street_part, city_part] ->
        street = String.trim(street_part)
        city_postal = String.trim(city_part)
        
        # Try to extract postal code (pattern: digits + letters)
        case Regex.run(~r/^(\d{4}\s?[A-Z]{2})\s+(.+)$/, city_postal) do
          [_full, postal_code, city] ->
            {street, String.trim(city), String.trim(postal_code)}
          _ ->
            # Fallback if parsing fails
            {street, city_postal, "0000 AA"}
        end
      
      _ ->
        # Fallback for unparseable addresses
        {delivery_address, "Amsterdam", "1000 AA"}
    end
  end
  
  defp broadcast_email_verified(email) do
    Phoenix.PubSub.broadcast(
      Eatfair.PubSub,
      "email_verification:#{email}",
      {:email_verified, email}
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
