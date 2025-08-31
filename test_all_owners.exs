# Test script to check all restaurant owners
{:ok, _} = Application.ensure_all_started(:eatfair)

# Load the actual user and check password hash
alias Eatfair.Accounts

# Test the main restaurant owners mentioned in README
owners = [
  {"marco@bellaitalia.com", "Marco Rossi"},
  {"wei@goldenlotus.com", "Wei Chen"},
  {"marie@jordaanbistro.com", "Marie Dubois"},
  {"owner@nightowl.nl", "Night Owl Manager"},
  {"test@eatfair.nl", "Test Customer"}
]

password = "password123456"

Enum.each(owners, fn {email, expected_name} ->
  case Accounts.get_user_by_email(email) do
    nil ->
      IO.puts("❌ #{email} - User not found")

    user ->
      name_match = user.name == expected_name
      confirmed = !is_nil(user.confirmed_at)
      has_password = !is_nil(user.hashed_password)
      password_valid = Eatfair.Accounts.User.valid_password?(user, password)
      auth_works = !is_nil(Accounts.get_user_by_email_and_password(email, password))

      status =
        if name_match and confirmed and has_password and password_valid and auth_works,
          do: "✅",
          else: "⚠️"

      IO.puts("#{status} #{email} (#{user.role})")
      IO.puts("   Name: #{user.name} #{if name_match, do: "✅", else: "❌"}")
      IO.puts("   Confirmed: #{confirmed} #{if confirmed, do: "✅", else: "❌"}")
      IO.puts("   Has password: #{has_password} #{if has_password, do: "✅", else: "❌"}")
      IO.puts("   Password valid: #{password_valid} #{if password_valid, do: "✅", else: "❌"}")
      IO.puts("   Auth function works: #{auth_works} #{if auth_works, do: "✅", else: "❌"}")
      IO.puts("")
  end
end)
