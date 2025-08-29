defmodule Eatfair.Accounts.EmailVerificationTest do
  use Eatfair.DataCase

  alias Eatfair.Accounts.EmailVerification
  alias Eatfair.Accounts
  alias Eatfair.Orders

  describe "email_verification schema" do
    test "changeset/2 validates required fields" do
      changeset = EmailVerification.changeset(%EmailVerification{}, %{})
      
      assert changeset.valid? == false
      assert errors_on(changeset) == %{
        email: ["can't be blank"],
        token: ["can't be blank"], 
        expires_at: ["can't be blank"]
      }
    end

    test "changeset/2 validates email format" do
      changeset = EmailVerification.changeset(%EmailVerification{}, %{
        email: "invalid-email",
        token: EmailVerification.generate_token(),
        expires_at: DateTime.utc_now()
      })
      
      refute changeset.valid?
      assert "must be a valid email" in errors_on(changeset).email
    end

    test "changeset/2 validates token length" do
      changeset = EmailVerification.changeset(%EmailVerification{}, %{
        email: "test@example.com",
        token: "short",
        expires_at: DateTime.utc_now()
      })
      
      refute changeset.valid?
      assert "should be 43 character(s)" in errors_on(changeset).token
    end

    test "changeset/2 accepts valid data" do
      token = EmailVerification.generate_token()
      changeset = EmailVerification.changeset(%EmailVerification{}, %{
        email: "test@example.com",
        token: token,
        expires_at: DateTime.utc_now()
      })
      
      assert changeset.valid?
    end
  end

  describe "generate_token/0" do
    test "generates a 43-character base64 token" do
      token = EmailVerification.generate_token()
      
      assert is_binary(token)
      assert String.length(token) == 43
      assert Base.url_decode64(token, padding: false) |> elem(0) == :ok
    end

    test "generates unique tokens" do
      token1 = EmailVerification.generate_token()
      token2 = EmailVerification.generate_token()
      
      assert token1 != token2
    end
  end

  describe "valid?/1" do
    test "returns true for non-expired verification" do
      future_time = DateTime.add(DateTime.utc_now(), 3600) # 1 hour from now
      verification = %EmailVerification{expires_at: future_time}
      
      assert EmailVerification.valid?(verification)
    end

    test "returns false for expired verification" do
      past_time = DateTime.add(DateTime.utc_now(), -3600) # 1 hour ago
      verification = %EmailVerification{expires_at: past_time}
      
      refute EmailVerification.valid?(verification)
    end
  end

  describe "verified?/1" do
    test "returns false when verified_at is nil" do
      verification = %EmailVerification{verified_at: nil}
      
      refute EmailVerification.verified?(verification)
    end

    test "returns true when verified_at is set" do
      verification = %EmailVerification{verified_at: DateTime.utc_now()}
      
      assert EmailVerification.verified?(verification)
    end
  end
end
