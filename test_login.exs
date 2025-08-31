# Test script to debug login issues
{:ok, _} = Application.ensure_all_started(:eatfair)

email = "owner@nightowl.nl"
password = "password123456"

# Load the actual user and check password hash
alias Eatfair.Accounts

case Accounts.get_user_by_email(email) do
  nil ->
    IO.puts("❌ User not found in database")
    
  user ->
    IO.puts("✅ User found:")
    IO.puts("   Email: #{user.email}")
    IO.puts("   Name: #{user.name}")
    IO.puts("   Role: #{user.role}")
    IO.puts("   Confirmed: #{user.confirmed_at}")
    IO.puts("   Has hashed password: #{!is_nil(user.hashed_password)}")
    
    # Test password verification
    if Eatfair.Accounts.User.valid_password?(user, password) do
      IO.puts("✅ Password is correct")
    else
      IO.puts("❌ Password is incorrect")
    end
    
    # Test the complete authentication function
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        IO.puts("❌ get_user_by_email_and_password returned nil")
      _user ->
        IO.puts("✅ get_user_by_email_and_password returned user")
    end
end
