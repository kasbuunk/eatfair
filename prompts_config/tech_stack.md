# EatFair Technology Stack Configuration

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

#### User Context Access
- **Always use**: `@current_scope.user` in templates and LiveView
- **Never use**: `@current_user` (does not exist)
- **Context**: Authentication provides `current_scope` assign

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
