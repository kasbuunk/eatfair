# EatFair Technical Stack Configuration

**Reference**: This file is referenced from WARP.md and AGENTS.md

This file provides technology-specific patterns and conventions for EatFair development.

## Core Technology Stack

### Phoenix LiveView (Primary Web Framework)
- **Version**: Phoenix v1.8 with LiveView
- **Authentication**: Phoenix.gen.auth with scope-based authorization
- **Components**: Use built-in `<.input>` and `<.icon>` components from core_components.ex
- **Templates**: HEEx templates (.html.heex files) exclusively

### Elixir Language Patterns  
- **Version**: Latest stable Elixir
- **OTP**: Standard OTP patterns for supervision and process management
- **Pattern Matching**: Preferred over conditionals for control flow
- **Error Handling**: Tagged tuples (`{:ok, result}` / `{:error, reason}`) pattern

### Database & Data Layer
- **Database**: SQLite (adequate for current MVP scale)
- **ORM**: Ecto with standard Phoenix context patterns
- **Migrations**: Standard Ecto migrations for schema changes
- **Seeds**: Comprehensive seed data for development and testing

### Testing Framework
- **Test Runner**: ExUnit (Elixir's built-in testing framework)
- **LiveView Testing**: Phoenix.LiveViewTest for UI interaction testing  
- **Test Organization**: Test files mirror lib/ directory structure
- **Performance**: Full test suite should complete in <30 seconds

## Development Patterns

### Phoenix LiveView Patterns

#### Authentication Routes
```elixir
# Routes requiring authentication
live_session :require_authenticated_user,
  on_mount: [{EatfairWeb.UserAuth, :require_authenticated}] do
  # Authenticated routes here
end

# Routes with optional authentication  
live_session :current_user,
  on_mount: [{EatfairWeb.UserAuth, :mount_current_scope}] do
  # Public routes with user context here
end
```

#### Authentication Guidelines
- **Always** handle authentication flow at the router level with proper redirects
- **Always** be mindful of where to place routes - `phx.gen.auth` creates multiple router plugs and `live_session` scopes
- **Never** duplicate `live_session` names (must be grouped in a single block)
- For controller routes that require authentication, use `pipe_through [:browser, :require_authenticated_user]`

#### User Context Access
- **Always use**: `@current_scope.user` in templates and LiveView
- **Never use**: `@current_user` (does not exist)
- **Context**: Authentication provides `current_scope` assign
- When you hit `current_scope` errors, check your router configuration and ensure correct `live_session` usage

#### LiveView Memory Management
```elixir
# Use streams for collections (avoid memory issues)
stream(socket, :restaurants, restaurants)

# Avoid large assigns
assign(socket, :restaurants, restaurants) # ❌ Memory heavy
```

#### Component Usage
```elixir
# Use built-in components
<.input name="email" type="email" />  # ✅ Correct
<.icon name="hero-x-mark" class="w-5 h-5" />  # ✅ Correct

# Avoid external component libraries
<custom-input />  # ❌ Avoid
```

#### HEEx Template Patterns
```heex
<!-- Always begin LiveView templates with layout wrapper -->
<Layouts.app flash={@flash} current_scope={@current_scope}>
  <!-- Template content -->
</Layouts.app>

<!-- Use list syntax for conditional classes -->
<a class={[
  "px-2 text-white",
  @active && "bg-blue-500",
  if(@error, do: "border-red-500", else: "border-gray-200")
]}>
  Link
</a>

<!-- Interpolation patterns -->
<div id={@element_id}>
  {@content}
  <%= if @show_content do %>
    More content
  <% end %>
</div>

<!-- Never use these patterns -->
<!-- <div id="<%= @invalid %>"> INVALID -->
<!-- <% Enum.each(@items, fn item -> %> INVALID -->
```

#### LiveView Streams
```elixir
# Always use streams for collections to avoid memory issues
def handle_event("load_messages", _, socket) do
  messages = list_messages()
  {:noreply, stream(socket, :messages, messages)}
end

def handle_event("filter", %{"filter" => filter}, socket) do
  messages = list_messages(filter)
  {:noreply, stream(socket, :messages, messages, reset: true)}
end
```

```heex
<!-- Template for streams -->
<div id="messages" phx-update="stream">
  <div class="hidden only:block">No messages yet</div>
  <div :for={{id, msg} <- @streams.messages} id={id}>
    {msg.text}
  </div>
</div>
```

#### Form Handling Patterns
```elixir
# Always use to_form/2 in LiveView for form assignment
def mount(_params, _session, socket) do
  changeset = User.changeset(%User{})
  {:ok, assign(socket, form: to_form(changeset))}
end

def handle_event("validate", %{"user" => user_params}, socket) do
  changeset = User.changeset(%User{}, user_params)
  {:noreply, assign(socket, form: to_form(changeset))}
end
```

```heex
<!-- Always use @form in templates, never @changeset -->
<.form for={@form} id="user-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:email]} type="email" label="Email" />
  <.input field={@form[:name]} type="text" label="Name" />
</.form>

<!-- NEVER do this (forbidden) -->
<!-- <.form for={@changeset}> INVALID -->
<!-- <.input field={@changeset[:field]}> INVALID -->
```

### Elixir Development Patterns

#### Data Structure Access
```elixir
# List access (never use index syntax)
Enum.at(mylist, i)  # ✅ Correct
mylist[i]  # ❌ Invalid in Elixir

# Struct field access  
my_struct.field  # ✅ Correct
my_struct[:field]  # ❌ Don't use Access on structs
```

#### Variable Binding in Block Expressions
```elixir
# Correct pattern
socket = 
  if connected?(socket) do
    assign(socket, :val, val)
  else
    socket
  end

# Incorrect pattern  
if connected?(socket) do
  socket = assign(socket, :val, val)  # ❌ Won't work
end
```

#### Additional Elixir Guidelines
- **Never** nest multiple modules in the same file (causes cyclic dependencies)
- **Never** use `String.to_atom/1` on user input (memory leak risk)
- **Predicate functions** should end with `?` and not start with `is_`
- **OTP naming**: Use names in child specs: `{DynamicSupervisor, name: MyApp.MySup}`
- **Concurrent enumeration**: Use `Task.async_stream/3` with `timeout: :infinity`
- **Date/time**: Use built-in `Date`, `Time`, `DateTime`, `Calendar` modules
- **HTTP requests**: Use `:req` library (included), avoid `:httpoison`, `:tesla`
- **Conditional logic**: Use `cond` or `case` for multiple conditions, never `elsif`

### Database & Ecto Patterns

#### Schema Fields
```elixir
# Always use :string type, even for long text
field :description, :string  # ✅ Correct  
field :description, :text     # ❌ Use :string instead
```

#### Changeset Access
```elixir
# Access changeset fields properly
Ecto.Changeset.get_field(changeset, :field)  # ✅ Correct
changeset[:field]  # ❌ Don't use Access on changesets
```

#### Preloading Associations
```elixir
# Always preload in queries when accessed in templates
from(m in Message, preload: [:user])  # ✅ When accessing message.user.email
```

#### EatFair Schema Patterns
```elixir
# Core business entities follow standard patterns:
# - User management: accounts context with role-based access
# - Restaurant management: restaurants context with geographic fields
# - Order management: orders context with status tracking
# - Supporting entities: addresses, payments, notifications

# Geographic data patterns
field :latitude, :decimal, precision: 10, scale: 6
field :longitude, :decimal, precision: 10, scale: 6
field :delivery_radius_km, :integer

# Status tracking patterns
field :status, :string  # enum-like: "pending", "confirmed", "delivered"
field :confirmed_at, :utc_datetime
field :delivered_at, :utc_datetime

# Financial data patterns
field :total_price, :decimal, precision: 10, scale: 2
field :amount, :decimal, precision: 10, scale: 2

# Foreign key relationships
belongs_to :user, User
belongs_to :restaurant, Restaurant  
belongs_to :customer, User, foreign_key: :customer_id
has_many :addresses, Address
many_to_many :cuisines, Cuisine, join_through: "restaurant_cuisines"
```

## Testing Patterns

### Phoenix LiveView Testing
```elixir
# Use element-based assertions
assert has_element?(view, "[data-role=submit-button]")

# Avoid raw HTML assertions  
refute html =~ "Some text"  # ❌ Brittle

# Test user interactions
view
|> element("[data-role=form]")
|> render_submit(%{user: %{email: "test@example.com"}})
```

### Test Organization
- **File Structure**: Mirror lib/ directory in test/
- **Test Categories**: Feature tests, context tests, component tests
- **Data Setup**: Use factories or seed data patterns
- **Performance**: Each test should run in <1 second

### Quality Gates
```bash
# Pre-commit validation commands
mix test                    # All tests pass
mix format                  # Code formatting  
mix compile --warnings-as-errors  # No compilation warnings
mix credo                  # Static analysis
mix deps.audit             # Security audit
```

## Development Workflow

### File Structure
```
lib/eatfair_web/
├── controllers/         # Phoenix controllers
├── live/               # LiveView modules  
├── components/         # LiveView components
└── templates/          # HEEx templates

lib/eatfair/
├── accounts/          # User management context
├── restaurants/       # Restaurant management context  
└── orders/           # Order processing context
```

### Git Workflow  
- **Conventional Commits**: `type(scope): description` format
- **Branch Strategy**: Feature branches merged to main
- **Quality Gates**: All tests pass, formatting applied, no warnings

### Documentation Updates
When completing features:
1. Update `documentation/legacy_implementation_log.md` with progress
2. Mark features as ✅ Complete with test file references
3. Update overall MVP progress percentage
4. Document any architectural decisions in ADRs

## Configuration References

See also:
- `workflows.md` - EatFair development processes  
- `quality_standards.md` - Testing and quality approaches
- `project_context.md` - Business domain context
