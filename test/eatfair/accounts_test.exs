defmodule Eatfair.AccountsTest do
  use Eatfair.DataCase

  alias Eatfair.Accounts

  import Eatfair.AccountsFixtures
  import Ecto.Query
  alias Eatfair.Accounts.{User, UserToken, EmailVerification}
  alias Eatfair.Orders
  alias Eatfair.Orders.Order

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture() |> set_password()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture() |> set_password()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users without password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_user_email(user, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(
          %User{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, {user, expired_tokens}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, {_, _}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"
      assert user_token.authenticated_at != nil

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      user = %{user | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == user.authenticated_at
      assert DateTime.compare(user_token.inserted_at, user.authenticated_at) == :gt
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "confirms user and expires tokens" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, {user, [%{token: ^hashed_token}]}} =
               Accounts.login_user_by_magic_link(encoded_token)

      assert user.confirmed_at
    end

    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, {^user, []}} = Accounts.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = unconfirmed_user_fixture()

      {1, nil} =
        Repo.update_all(from(u in User, where: u.id == ^user.id),
          set: [hashed_password: "hashed"]
        )

      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_user_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "send_verification_email/2" do
    test "creates email verification record and sends email" do
      email = "test@example.com"

      assert {:ok, verification} = Accounts.send_verification_email(email)

      # Verify record was created
      assert verification.email == email
      assert verification.token
      assert String.length(verification.token) == 43
      assert verification.expires_at
      refute verification.verified_at

      # Verify it's in the database
      db_verification = Repo.get!(EmailVerification, verification.id)
      assert db_verification.email == email
    end

    test "associates verification with order when provided" do
      # Create a restaurant owner first
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      # Create a restaurant
      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      # Create an order
      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: "test@example.com",
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      assert {:ok, verification} =
               Accounts.send_verification_email(order.customer_email, order: order)

      assert verification.email == order.customer_email
      assert verification.order_id == order.id

      # Verify order status was updated to pending
      updated_order = Orders.get_order!(order.id)
      assert updated_order.email_status == "pending"
    end

    test "cleans up expired verifications for same email" do
      email = "test@example.com"

      # Create an expired verification
      expired_verification =
        Repo.insert!(%EmailVerification{
          email: email,
          token: EmailVerification.generate_token(),
          # 1 hour ago
          expires_at: DateTime.add(DateTime.utc_now() |> DateTime.truncate(:second), -3600),
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        })

      assert {:ok, new_verification} = Accounts.send_verification_email(email)

      # Expired verification should be deleted
      refute Repo.get(EmailVerification, expired_verification.id)

      # New verification should exist
      assert Repo.get(EmailVerification, new_verification.id)
    end
  end

  describe "verify_email/1" do
    setup do
      email = "test@example.com"

      {:ok, verification} =
        Accounts.create_email_verification(%{
          email: email,
          token: EmailVerification.generate_token(),
          # 1 hour from now
          expires_at: DateTime.add(DateTime.utc_now(), 3600)
        })

      %{verification: verification, email: email}
    end

    test "verifies email with valid token", %{verification: verification} do
      assert {:ok, verified} = Accounts.verify_email(verification.token)

      assert verified.id == verification.id
      assert verified.verified_at
      assert DateTime.compare(verified.verified_at, DateTime.utc_now()) in [:lt, :eq]
    end

    test "returns error for non-existent token" do
      assert {:error, :not_found} = Accounts.verify_email("non-existent-token")
    end

    test "returns error for expired token", %{verification: verification} do
      # Update to expired
      Repo.update!(
        EmailVerification.changeset(verification, %{
          # 1 hour ago
          expires_at: DateTime.add(DateTime.utc_now(), -3600)
        })
      )

      assert {:error, :expired} = Accounts.verify_email(verification.token)
    end

    test "returns error for already verified token", %{verification: verification} do
      # First verification should succeed
      assert {:ok, _} = Accounts.verify_email(verification.token)

      # Second verification should fail
      assert {:error, :already_verified} = Accounts.verify_email(verification.token)
    end

    test "updates associated order email status when order exists", %{verification: verification} do
      # Create a restaurant owner first
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      # Create a restaurant and order
      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: verification.email,
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      # Update verification to associate with order
      Repo.update!(EmailVerification.changeset(verification, %{order_id: order.id}))

      assert {:ok, _} = Accounts.verify_email(verification.token)

      # Check order status was updated
      updated_order = Orders.get_order!(order.id)
      assert updated_order.email_status == "verified"
      assert updated_order.email_verified_at
    end
  end

  describe "create_account_from_order/2" do
    setup do
      # Create a restaurant owner first
      owner =
        Repo.insert!(%Eatfair.Accounts.User{
          email: "owner@restaurant.com",
          confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      # Create a restaurant
      restaurant =
        Repo.insert!(%Eatfair.Restaurants.Restaurant{
          name: "Test Restaurant",
          address: "Test Street 123, 1000 AB Amsterdam",
          owner_id: owner.id
        })

      # Use unique email for each test run
      unique_email = unique_user_email()

      {:ok, order} =
        Orders.create_anonymous_order(%{
          restaurant_id: restaurant.id,
          customer_email: unique_email,
          customer_phone: "+31 6 12345678",
          delivery_address: "Delivery Street 456, 1000 AB Amsterdam",
          total_price: Decimal.new("25.50")
        })

      %{order: order}
    end

    test "creates new user account from order", %{order: order} do
      assert {:ok, user, updated_order} = Accounts.create_account_from_order(order)

      # Verify user was created correctly
      assert user.email == order.customer_email
      assert user.phone_number == order.customer_phone
      # Should be auto-confirmed
      assert user.confirmed_at

      # Verify order was associated with user
      assert updated_order.customer_id == user.id
      assert updated_order.account_created_from_order

      # Verify address was created
      addresses = Accounts.list_user_addresses(user.id)
      assert length(addresses) == 1
      address = hd(addresses)
      # Parsed from order.delivery_address
      assert address.street_address == "Delivery Street 456"
      # Parsed from order.delivery_address
      assert address.city == "Amsterdam"
      # Parsed from order.delivery_address
      assert address.postal_code == "1000 AB"
      assert address.is_default
    end

    test "associates order with existing user if email exists", %{order: order} do
      # When the order was created, a soft account was already created
      # Get the existing soft account user
      existing_user = Accounts.get_user_by_email(order.customer_email)
      # Should exist from order creation
      assert existing_user
      # Should be a soft account
      assert is_nil(existing_user.phone_number)
      # Should be unconfirmed
      assert is_nil(existing_user.confirmed_at)

      assert {:ok, user, updated_order} = Accounts.create_account_from_order(order)

      # Should return the same user, now upgraded
      assert user.id == existing_user.id
      # Should now have phone
      assert user.phone_number == order.customer_phone
      # Should now be confirmed
      assert user.confirmed_at

      # Order should be associated with existing user
      assert updated_order.customer_id == existing_user.id
      assert updated_order.account_created_from_order
    end

    test "allows custom user parameters", %{order: order} do
      custom_params = %{name: "Custom Name"}

      assert {:ok, user, _updated_order} =
               Accounts.create_account_from_order(order, custom_params)

      assert user.name == "Custom Name"
    end
  end

  describe "get_verification_by_token/1" do
    test "returns verification with valid token" do
      token = EmailVerification.generate_token()

      {:ok, verification} =
        Accounts.create_email_verification(%{
          email: "test@example.com",
          token: token,
          expires_at: DateTime.add(DateTime.utc_now(), 3600)
        })

      found_verification = Accounts.get_verification_by_token(token)
      assert found_verification.id == verification.id
      assert found_verification.email == verification.email
    end

    test "returns nil for non-existent token" do
      refute Accounts.get_verification_by_token("non-existent")
    end
  end

  describe "create_email_verification/1" do
    test "creates email verification with valid attributes" do
      expires_at = DateTime.add(DateTime.utc_now(), 3600) |> DateTime.truncate(:second)

      attrs = %{
        email: "test@example.com",
        token: EmailVerification.generate_token(),
        expires_at: expires_at
      }

      assert {:ok, verification} = Accounts.create_email_verification(attrs)
      assert verification.email == attrs.email
      assert verification.token == attrs.token
      assert DateTime.compare(verification.expires_at, expires_at) == :eq
    end

    test "fails with invalid attributes" do
      assert {:error, changeset} = Accounts.create_email_verification(%{})

      assert errors_on(changeset) == %{
               email: ["can't be blank"],
               token: ["can't be blank"],
               expires_at: ["can't be blank"]
             }
    end
  end

  describe "list_email_verifications/1" do
    test "returns verifications for email address" do
      email = "test@example.com"

      # Create multiple verifications for same email
      {:ok, verification1} =
        Accounts.create_email_verification(%{
          email: email,
          token: EmailVerification.generate_token(),
          expires_at: DateTime.add(DateTime.utc_now(), 3600)
        })

      {:ok, verification2} =
        Accounts.create_email_verification(%{
          email: email,
          token: EmailVerification.generate_token(),
          expires_at: DateTime.add(DateTime.utc_now(), 3600)
        })

      # Create verification for different email
      {:ok, _other_verification} =
        Accounts.create_email_verification(%{
          email: "other@example.com",
          token: EmailVerification.generate_token(),
          expires_at: DateTime.add(DateTime.utc_now(), 3600)
        })

      verifications = Accounts.list_email_verifications(email)

      # Should only return verifications for the specified email
      assert length(verifications) == 2
      verification_ids = Enum.map(verifications, & &1.id)
      assert verification1.id in verification_ids
      assert verification2.id in verification_ids
    end

    test "limits results to 10" do
      email = "test@example.com"

      # Create 15 verifications
      for _i <- 1..15 do
        Accounts.create_email_verification(%{
          email: email,
          token: EmailVerification.generate_token(),
          expires_at: DateTime.add(DateTime.utc_now(), 3600)
        })
      end

      verifications = Accounts.list_email_verifications(email)
      assert length(verifications) == 10
    end
  end
end
