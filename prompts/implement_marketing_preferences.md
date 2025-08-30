# Implement Marketing Preferences & User Settings Enhancement

*Comprehensive prompt for implementing marketing preferences integrated with user settings, following Phoenix conventions and admin-friendly design patterns.*

---

## 🎯 **PROMPT ACTIVATION**

**One-liner Usage**: 
```
Implement marketing preferences using the prompt in IMPLEMENT_MARKETING_PREFERENCES.md
```

**Full Process Usage**:
```
Use IMPLEMENT_MARKETING_PREFERENCES.md to implement comprehensive marketing preferences with user settings integration following Phoenix/Elixir conventions
```

---

## 📋 **PROJECT CONTEXT & DISCOVERY**

### **Current System Analysis**

Before beginning implementation, analyze the existing codebase to understand:

#### **1. Current User Settings Architecture**
```elixir
# Examine existing user settings structure
find_files(["**/user_live/*.ex", "**/user_settings*.ex"], "/Users/kasbuunk/git/github.com/kasbuunk/eatfair")
```

**Key files to analyze**:
- `lib/eatfair_web/live/user_live/user_settings_live.ex` - Current settings interface
- `lib/eatfair/accounts/user.ex` - User schema and fields
- `lib/eatfair/accounts.ex` - User context functions
- `test/eatfair_web/live/user_settings_live_test.ex` - Existing settings tests

#### **2. Database Schema Investigation**
```elixir
# Check current User schema structure
grep(["defp changeset", "schema \"users\"", "field :"], "/Users/kasbuunk/git/github.com/kasbuunk/eatfair/lib/eatfair/accounts/user.ex")
```

**Analyze**:
- Current user fields and their types
- Existing preference-related fields
- Validation patterns and constraints
- Privacy and security field handling

#### **3. Existing Settings UI Patterns**
```elixir
# Examine current settings LiveView implementation
read_files(["/Users/kasbuunk/git/github.com/kasbuunk/eatfair/lib/eatfair_web/live/user_live/user_settings_live.ex"])
```

**Understand**:
- Form handling patterns (`phx-change`, `phx-submit`)
- Validation and error display patterns
- Flash message patterns
- Navigation and redirect patterns

---

## 🏗 **IMPLEMENTATION REQUIREMENTS**

### **Phase 1: Database Schema Enhancement**

#### **1.1 User Schema Migration**
Create migration to add marketing preference fields:

```elixir
# File: priv/repo/migrations/YYYYMMDDHHMMSS_add_marketing_preferences_to_users.exs
defmodule Eatfair.Repo.Migrations.AddMarketingPreferencesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Core marketing preferences
      add :marketing_opt_in, :boolean, default: false, null: false
      add :promotional_emails, :boolean, default: false, null: false
      add :order_updates, :boolean, default: true, null: false
      add :loyalty_program_updates, :boolean, default: false, null: false
      
      # Communication preferences
      add :sms_notifications, :boolean, default: false, null: false
      add :push_notifications, :boolean, default: true, null: false
      
      # Frequency preferences
      add :email_frequency, :string, default: "weekly", null: false # "daily", "weekly", "monthly", "never"
      
      # Preference management
      add :preferences_updated_at, :utc_datetime
      add :unsubscribe_token, :string # For one-click unsubscribe links
    end

    # Add index for admin queries and unsubscribe tokens
    create index(:users, [:marketing_opt_in])
    create index(:users, [:email_frequency])
    create unique_index(:users, [:unsubscribe_token])
  end
end
```

#### **1.2 User Schema Updates**
Update `lib/eatfair/accounts/user.ex`:

```elixir
# Add marketing preference fields to User schema
schema "users" do
  # ... existing fields
  
  # Marketing preferences
  field :marketing_opt_in, :boolean, default: false
  field :promotional_emails, :boolean, default: false
  field :order_updates, :boolean, default: true
  field :loyalty_program_updates, :boolean, default: false
  
  # Communication preferences  
  field :sms_notifications, :boolean, default: false
  field :push_notifications, :boolean, default: true
  
  # Frequency preferences
  field :email_frequency, Ecto.Enum, values: [:daily, :weekly, :monthly, :never], default: :weekly
  
  # Preference management
  field :preferences_updated_at, :utc_datetime
  field :unsubscribe_token, :string
end

# Add marketing preferences changeset
def marketing_preferences_changeset(user, attrs) do
  user
  |> cast(attrs, [
    :marketing_opt_in, :promotional_emails, :order_updates, 
    :loyalty_program_updates, :sms_notifications, :push_notifications,
    :email_frequency
  ])
  |> validate_required([:marketing_opt_in, :order_updates, :push_notifications, :email_frequency])
  |> validate_inclusion(:email_frequency, [:daily, :weekly, :monthly, :never])
  |> put_change(:preferences_updated_at, DateTime.utc_now())
  |> maybe_generate_unsubscribe_token()
  |> validate_marketing_consistency()
end

# Ensure consistent marketing preferences
defp validate_marketing_consistency(changeset) do
  marketing_opt_in = get_change(changeset, :marketing_opt_in) || get_field(changeset, :marketing_opt_in)
  
  if not marketing_opt_in do
    # If user opts out of marketing, disable all marketing-related preferences
    changeset
    |> put_change(:promotional_emails, false)
    |> put_change(:loyalty_program_updates, false)
  else
    changeset
  end
end
```

### **Phase 2: Context Functions Enhancement**

#### **2.1 Accounts Context Updates**
Update `lib/eatfair/accounts.ex`:

```elixir
# Add marketing preferences management functions
def get_user_marketing_preferences(user_id) do
  user = get_user!(user_id)
  %{
    marketing_opt_in: user.marketing_opt_in,
    promotional_emails: user.promotional_emails,
    order_updates: user.order_updates,
    loyalty_program_updates: user.loyalty_program_updates,
    sms_notifications: user.sms_notifications,
    push_notifications: user.push_notifications,
    email_frequency: user.email_frequency,
    preferences_updated_at: user.preferences_updated_at
  }
end

def update_marketing_preferences(user, attrs) do
  user
  |> User.marketing_preferences_changeset(attrs)
  |> Repo.update()
end

def change_marketing_preferences(user, attrs \\ %{}) do
  User.marketing_preferences_changeset(user, attrs)
end

# Admin functions for marketing management
def list_marketing_opted_in_users(opts \\ []) do
  limit = Keyword.get(opts, :limit, 1000)
  email_frequency = Keyword.get(opts, :frequency, :all)
  
  query = from u in User, 
    where: u.marketing_opt_in == true and u.promotional_emails == true
  
  query = if email_frequency != :all do
    from u in query, where: u.email_frequency == ^email_frequency
  else
    query
  end
  
  query
  |> limit(^limit)
  |> Repo.all()
end

def unsubscribe_by_token(token) when is_binary(token) do
  case get_user_by_unsubscribe_token(token) do
    nil -> {:error, :not_found}
    user -> 
      update_marketing_preferences(user, %{
        marketing_opt_in: false,
        promotional_emails: false,
        loyalty_program_updates: false
      })
  end
end

defp get_user_by_unsubscribe_token(token) do
  Repo.get_by(User, unsubscribe_token: token)
end
```

### **Phase 3: User Settings LiveView Enhancement**

#### **3.1 Settings LiveView Structure**
Update `lib/eatfair_web/live/user_live/user_settings_live.ex`:

```elixir
# Add marketing preferences to existing user settings
def mount(_params, _session, socket) do
  user = socket.assigns.current_scope.user
  
  {:ok,
   socket
   |> assign(:page_title, "Account Settings")
   |> assign(:current_password, nil)
   |> assign(:current_section, :profile) # Add section management
   |> assign_forms(user)}
end

defp assign_forms(socket, user) do
  socket
  |> assign(:profile_form, to_form(Accounts.change_user_profile(user)))
  |> assign(:email_form, to_form(Accounts.change_user_email(user)))  
  |> assign(:password_form, to_form(Accounts.change_user_password(user)))
  |> assign(:marketing_form, to_form(Accounts.change_marketing_preferences(user)))
end

# Add section handling
def handle_event("switch_section", %{"section" => section}, socket) do
  {:noreply, assign(socket, :current_section, String.to_existing_atom(section))}
end

# Marketing preferences form handling
def handle_event("validate_marketing", %{"user" => marketing_params}, socket) do
  marketing_form =
    socket.assigns.current_scope.user
    |> Accounts.change_marketing_preferences(marketing_params)
    |> Map.put(:action, :validate)
    |> to_form()

  {:noreply, assign(socket, :marketing_form, marketing_form)}
end

def handle_event("update_marketing", %{"user" => marketing_params}, socket) do
  user = socket.assigns.current_scope.user

  case Accounts.update_marketing_preferences(user, marketing_params) do
    {:ok, user} ->
      info = "Marketing preferences updated successfully!"

      {:noreply,
       socket
       |> put_flash(:info, info)
       |> assign(:marketing_form, to_form(Accounts.change_marketing_preferences(user)))}

    {:error, changeset} ->
      {:noreply, assign(socket, :marketing_form, to_form(changeset))}
  end
end
```

#### **3.2 Settings Template Enhancement**
Update `lib/eatfair_web/live/user_live/user_settings_live.html.heex`:

```heex
<!-- Add tabbed settings interface -->
<div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
  <.header>
    Account Settings
    <:subtitle>Manage your profile, preferences, and security settings</:subtitle>
  </.header>

  <!-- Settings Navigation -->
  <div class="mt-8">
    <nav class="flex space-x-8 border-b border-gray-200" aria-label="Settings">
      <button
        phx-click="switch_section"
        phx-value-section="profile"
        class={settings_tab_class(@current_section == :profile)}
      >
        Profile
      </button>
      <button
        phx-click="switch_section"
        phx-value-section="email"
        class={settings_tab_class(@current_section == :email)}
      >
        Email & Security
      </button>
      <button
        phx-click="switch_section"
        phx-value-section="marketing"
        class={settings_tab_class(@current_section == :marketing)}
      >
        Marketing & Notifications
      </button>
    </nav>
  </div>

  <!-- Settings Content -->
  <div class="mt-8">
    <%= if @current_section == :marketing do %>
      <.marketing_preferences_section form={@marketing_form} />
    <% end %>
    
    <!-- Other sections... -->
  </div>
</div>

<!-- Marketing Preferences Component -->
<.marketing_preferences_section :let={form}>
  <div class="bg-white shadow rounded-lg">
    <div class="px-6 py-4 border-b border-gray-200">
      <h3 class="text-lg font-medium text-gray-900">Marketing & Communication Preferences</h3>
      <p class="mt-1 text-sm text-gray-500">
        Choose how you'd like to receive updates and promotional content from EatFair.
      </p>
    </div>

    <.form for={form} phx-change="validate_marketing" phx-submit="update_marketing" class="p-6 space-y-6">
      <!-- Primary Marketing Opt-in -->
      <div class="relative">
        <.input
          field={form[:marketing_opt_in]}
          type="checkbox"
          label="Enable marketing communications"
          help="Receive promotional emails, special offers, and loyalty program updates"
        />
      </div>

      <!-- Conditional Marketing Options -->
      <div class={["space-y-4", unless(Ecto.Changeset.get_field(form.source, :marketing_opt_in), do: "opacity-50 pointer-events-none")]}>
        <.input
          field={form[:promotional_emails]}
          type="checkbox"
          label="Promotional emails"
          help="Special offers, discounts, and featured restaurants"
        />
        
        <.input
          field={form[:loyalty_program_updates]}
          type="checkbox"
          label="Loyalty program updates"
          help="Points balance, rewards, and exclusive member offers"
        />

        <.input
          field={form[:email_frequency]}
          type="select"
          label="Email frequency"
          options={[
            {"Daily", :daily},
            {"Weekly", :weekly}, 
            {"Monthly", :monthly},
            {"Never", :never}
          ]}
          help="How often you'd like to receive promotional emails"
        />
      </div>

      <!-- Communication Preferences -->
      <div class="border-t pt-6">
        <h4 class="text-md font-medium text-gray-900 mb-4">Communication Preferences</h4>
        
        <.input
          field={form[:order_updates]}
          type="checkbox"
          label="Order updates"
          help="Essential notifications about your orders (recommended)"
        />
        
        <.input
          field={form[:sms_notifications]}
          type="checkbox"
          label="SMS notifications"
          help="Receive order updates via text message"
        />
        
        <.input
          field={form[:push_notifications]}
          type="checkbox"
          label="Push notifications"
          help="Browser and app notifications for order status"
        />
      </div>

      <!-- Privacy Notice -->
      <div class="bg-blue-50 border border-blue-200 rounded-md p-4">
        <div class="flex">
          <.icon name="hero-information-circle" class="h-5 w-5 text-blue-400" />
          <div class="ml-3">
            <h4 class="text-sm font-medium text-blue-800">Your Privacy Matters</h4>
            <p class="mt-1 text-sm text-blue-700">
              We respect your privacy and will never sell your information. 
              You can change these preferences at any time.
              <.link href="/privacy" class="underline">Learn more</.link>.
            </p>
          </div>
        </div>
      </div>

      <div class="flex justify-end">
        <.button type="submit" phx-disable-with="Saving...">
          Save Preferences
        </.button>
      </div>
    </.form>
  </div>
</.marketing_preferences_section>
```

### **Phase 4: Account Setup Integration**

#### **4.1 Fix Account Setup TODO**
Update `lib/eatfair_web/live/user_live/account_setup.ex`:

```elixir
# Replace TODO with actual marketing preference storage
def handle_event("save", %{"user" => user_params} = params, socket) do
  marketing_opt_in = params["marketing_opt_in"] == "true"
  terms_accepted = params["terms_accepted"] == "true"

  if not terms_accepted do
    {:noreply,
     socket
     |> put_flash(:error, "You must accept the Terms and Conditions to continue.")
     |> assign(:terms_accepted, false)}
  else
    user = socket.assigns.current_scope.user
    
    # Multi-step update: password + marketing preferences
    with {:ok, {updated_user, _tokens}} <- Accounts.update_user_password(user, user_params),
         {:ok, _user} <- Accounts.update_marketing_preferences(updated_user, %{
           marketing_opt_in: marketing_opt_in,
           promotional_emails: marketing_opt_in, # Default to same as opt-in
           preferences_updated_at: DateTime.utc_now()
         }) do
      
      {:noreply,
       socket
       |> put_flash(:info, "Account setup completed successfully!")
       |> push_navigate(to: ~p"/users/settings")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> assign(:marketing_opt_in, marketing_opt_in)
         |> assign(:terms_accepted, terms_accepted)}
    end
  end
end
```

### **Phase 5: Admin Interface Enhancement**

#### **5.1 Admin Marketing Dashboard**
Create `lib/eatfair_web/live/admin_live/marketing_dashboard.ex`:

```elixir
defmodule EatfairWeb.AdminLive.MarketingDashboard do
  use EatfairWeb, :live_view
  
  alias Eatfair.Accounts
  
  def mount(_params, _session, socket) do
    if authorized?(socket.assigns.current_scope.user, :admin) do
      {:ok,
       socket
       |> assign(:page_title, "Marketing Dashboard")
       |> load_marketing_stats()
       |> load_marketing_users()}
    else
      {:ok, push_navigate(socket, to: "/")}
    end
  end
  
  defp load_marketing_stats(socket) do
    stats = %{
      total_opted_in: Accounts.count_users_by_marketing_status(:opted_in),
      total_opted_out: Accounts.count_users_by_marketing_status(:opted_out),
      weekly_frequency: Accounts.count_users_by_email_frequency(:weekly),
      monthly_frequency: Accounts.count_users_by_email_frequency(:monthly),
      daily_frequency: Accounts.count_users_by_email_frequency(:daily)
    }
    
    assign(socket, :marketing_stats, stats)
  end
end
```

### **Phase 6: Email Integration**

#### **6.1 Unsubscribe Links**
Update `lib/eatfair/accounts/user_notifier.ex`:

```elixir
# Add unsubscribe links to promotional emails
defp add_unsubscribe_footer(email_body, user) do
  base_url = EatfairWeb.Endpoint.url()
  unsubscribe_url = "#{base_url}/unsubscribe/#{user.unsubscribe_token}"
  settings_url = "#{base_url}/users/settings"
  
  """
  #{email_body}
  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  You received this email because you're subscribed to EatFair marketing updates.
  
  • Manage your preferences: #{settings_url}
  • Unsubscribe from all marketing: #{unsubscribe_url}
  
  EatFair respects your privacy. We will never sell your information.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  """
end
```

#### **6.2 Unsubscribe Controller**
Create `lib/eatfair_web/controllers/unsubscribe_controller.ex`:

```elixir
defmodule EatfairWeb.UnsubscribeController do
  use EatfairWeb, :controller
  
  alias Eatfair.Accounts
  
  def unsubscribe(conn, %{"token" => token}) do
    case Accounts.unsubscribe_by_token(token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "You have been successfully unsubscribed from all marketing emails.")
        |> redirect(to: ~p"/")
      
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Invalid unsubscribe link.")
        |> redirect(to: ~p"/")
    end
  end
end
```

---

## 🧪 **COMPREHENSIVE TEST STRATEGY**

### **Database Tests**
```elixir
# File: test/eatfair/accounts_test.exs
describe "marketing preferences" do
  test "update_marketing_preferences/2 with valid data updates preferences" do
    user = user_fixture()
    
    attrs = %{
      marketing_opt_in: true,
      promotional_emails: true,
      email_frequency: :weekly
    }
    
    assert {:ok, %User{} = updated_user} = Accounts.update_marketing_preferences(user, attrs)
    assert updated_user.marketing_opt_in == true
    assert updated_user.promotional_emails == true
    assert updated_user.email_frequency == :weekly
    assert updated_user.preferences_updated_at
  end
  
  test "marketing opt-out disables all promotional preferences" do
    user = user_fixture(%{marketing_opt_in: true, promotional_emails: true})
    
    attrs = %{marketing_opt_in: false}
    
    assert {:ok, %User{} = updated_user} = Accounts.update_marketing_preferences(user, attrs)
    assert updated_user.marketing_opt_in == false
    assert updated_user.promotional_emails == false
  end
end
```

### **LiveView Integration Tests**
```elixir
# File: test/eatfair_web/live/user_settings_live_test.exs
describe "marketing preferences section" do
  test "renders marketing preferences form", %{conn: conn, user: user} do
    {:ok, lv, html} = live(conn, ~p"/users/settings")
    
    # Switch to marketing section
    lv |> element("button", "Marketing & Notifications") |> render_click()
    
    assert has_element?(lv, "input[name='user[marketing_opt_in]']")
    assert has_element?(lv, "select[name='user[email_frequency]']")
  end
  
  test "updates marketing preferences successfully", %{conn: conn, user: user} do
    {:ok, lv, _html} = live(conn, ~p"/users/settings")
    
    # Switch to marketing section and update
    lv |> element("button", "Marketing & Notifications") |> render_click()
    
    lv
    |> form("[phx-submit='update_marketing']", user: %{
      marketing_opt_in: "true",
      promotional_emails: "true",
      email_frequency: "weekly"
    })
    |> render_submit()
    
    assert_redirect(lv, ~p"/users/settings")
    
    # Verify preferences were saved
    updated_user = Accounts.get_user!(user.id)
    assert updated_user.marketing_opt_in == true
    assert updated_user.promotional_emails == true
    assert updated_user.email_frequency == :weekly
  end
end
```

---

## 🎯 **QUALITY STANDARDS & SUCCESS CRITERIA**

### **Functional Requirements**
- [ ] Users can opt-in/out of marketing communications
- [ ] Granular control over email types and frequency
- [ ] Marketing opt-out disables all promotional communications
- [ ] One-click unsubscribe from emails works
- [ ] Admin can view marketing statistics and export user lists
- [ ] Account setup properly saves marketing preferences

### **Technical Requirements**
- [ ] Database migration runs without errors
- [ ] All existing tests continue to pass
- [ ] New functionality has comprehensive test coverage (>95%)
- [ ] Phoenix conventions followed (contexts, LiveViews, controllers)
- [ ] Proper error handling and validation
- [ ] Admin authorization properly implemented

### **User Experience Requirements**
- [ ] Settings interface is intuitive and well-organized
- [ ] Clear explanations of each preference type
- [ ] Immediate feedback on preference changes
- [ ] Unsubscribe process is straightforward
- [ ] Privacy information is clearly communicated

### **Privacy & Compliance**
- [ ] Marketing preferences default to opt-out
- [ ] Unsubscribe tokens are unique and secure
- [ ] User consent is properly tracked and timestamped
- [ ] Privacy policy accurately reflects marketing practices

---

## 🔧 **PHOENIX CONVENTIONS & BEST PRACTICES**

### **Schema Design**
- Use `boolean` fields with explicit `null: false` constraints
- Include timestamp fields for audit trails
- Add appropriate database indexes for performance
- Use `Ecto.Enum` for controlled string values

### **Context Functions**
- Keep business logic in context modules
- Use descriptive function names (`update_marketing_preferences/2`)
- Return consistent `{:ok, result} | {:error, changeset}` patterns
- Separate admin functions from user functions

### **LiveView Architecture**
- Use assign patterns consistently
- Handle form validation with `phx-change` events
- Provide immediate user feedback
- Follow existing UI patterns and components

### **Testing Strategy**
- Unit tests for context functions
- Integration tests for LiveView interactions  
- Controller tests for admin functionality
- Edge case testing for privacy compliance

---

## 📚 **REFERENCE MATERIALS**

### **Existing Codebase Patterns**
Study these files for implementation patterns:
- `lib/eatfair_web/live/user_live/user_settings_live.ex` - Settings UI patterns
- `lib/eatfair/accounts/user.ex` - Schema and changeset patterns  
- `lib/eatfair/accounts.ex` - Context function patterns
- `test/eatfair_web/live/user_settings_live_test.exs` - Testing patterns

### **Phoenix Documentation**
- [Ecto Schema](https://hexdocs.pm/ecto/Ecto.Schema.html)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
- [Phoenix Controllers](https://hexdocs.pm/phoenix/controllers.html)

---

*This comprehensive prompt ensures marketing preferences are implemented following Phoenix conventions with proper admin functionality, user experience, and privacy compliance.*
