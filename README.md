# Eatfair

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## 🚀 Quick Start Guide

### Setup & Development Server

```bash
# First time setup (installs deps, creates DB, seeds data)
mix setup

# Start the development server
mix phx.server

# Or start with interactive Elixir shell
iex -S mix phx.server
```

The application will be available at [`localhost:4000`](http://localhost:4000).

### Reset to Clean State

```bash
# Reset database and reseed with fresh data
mix ecto.reset

# Run seed script manually
mix run priv/repo/seeds.exs
```

---

## 👤 Test User Accounts

*All accounts use password: `password123456`*

### 🍽️ Restaurant Owners
| Name | Email | Restaurant | Location |
|------|-------|------------|----------|
| Marco Rossi | `marco@bellaitalia.com` | Bella Italia Amsterdam | Amsterdam |
| Wei Chen | `wei@goldenlotus.com` | Golden Lotus | Amsterdam |
| Marie Dubois | `marie@jordaanbistro.com` | Jordaan Bistro | Amsterdam |
| Raj Patel | `raj@spicegarden.com` | Spice Garden Utrecht | Utrecht |
| Carlos Mendoza | `carlos@utrechttaco.com` | Utrecht Taco Bar | Utrecht |

### 📱 Customer Accounts
| Name | Email | Location | Special Features |
|------|-------|----------|------------------|
| Test Customer | `test@eatfair.nl` | Central Amsterdam | General testing |
| Piet van Amsterdam | `piet@example.nl` | Amsterdam | Regular customer |
| Emma Janssen | `emma@example.nl` | Utrecht | Utrecht resident |
| Lisa de Vries | `lisa@example.nl` | Het Gooi | Distance boundary testing |
| Jan de Frequent | `frequent@example.nl` | Amsterdam | **Has test orders in all status states** |
| Sophie Vegano | `vegan@example.nl` | Amsterdam | Dietary preferences testing |
| Multi Address | `multi@example.nl` | Amsterdam | **Multiple addresses**: Work, Holiday Home, Parents' House |

### 🚚 Courier Accounts
| Name | Email | Location |
|------|-------|----------|
| Max Speedman | `courier1@example.nl` | East Amsterdam |
| Fietskoerier Utrecht | `courier2@example.nl` | Central Utrecht |
| Test Courier | `testcourier@eatfair.nl` | Central Amsterdam |

---

## 🧪 Testing & Development

### Running Tests

```bash
# Run all tests (163 tests, ~0.9 seconds)
mix test

# Run tests with detailed output
mix test --trace

# Run specific test file
mix test test/eatfair_web/integration/order_flow_test.exs

# Run only failed tests
mix test --failed
```

### Code Quality Checks

```bash
# Run all pre-commit checks (compile with warnings as errors, format, test)
mix precommit

# Individual quality checks
mix compile --warnings-as-errors  # Check for warnings
mix format                         # Format code
mix deps.unlock --unused           # Remove unused dependencies
```

### Database Operations

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Rollback migration
mix ecto.rollback
```

---

## 🎯 Manual Testing Scenarios

### Consumer Order Flow
1. **Login** as `test@eatfair.nl`
2. **Browse restaurants** on home page - restaurants are filtered by delivery range
3. **Select restaurant** within delivery radius (Amsterdam restaurants)
4. **Add items to cart** and proceed to checkout
5. **Complete order** with delivery information
6. **Track order status** - watch real-time updates

### Restaurant Owner Experience
1. **Login** as `marco@bellaitalia.com`
2. **Manage restaurant profile** at `/restaurant/dashboard`
3. **Edit menu items** - changes reflect immediately on customer side
4. **Process orders** at `/restaurant/orders` - organized by status
5. **Update order status** - customers see real-time updates

### Order Tracking Testing
1. **Login** as `frequent@example.nl`
2. **View order history** - account has orders in all status states
3. **Watch real-time updates** as restaurant updates order status
4. **Test notification system** - events logged for status changes

### Geographic & Address Testing
1. **Login** as `multi@example.nl`
2. **Manage multiple addresses** - Home, Work, Holiday Home, Parents' House
3. **Test delivery radius** - try ordering from different address locations
4. **Distance boundary testing** - restaurants outside radius show "unavailable"

### Review System Testing
1. **Login** as `frequent@example.nl` (has delivered orders)
2. **Submit reviews** - only allowed after order completion
3. **View restaurant ratings** - average ratings update automatically
4. **Test authorization** - cannot review without completing orders

---

## 📊 Project Status

- **Test Coverage**: 163 tests passing (100% success rate)
- **Test Execution Time**: ~0.9 seconds
- **MVP Completion**: 75% (Features complete, quality engineering required)
- **Production Readiness**: Quality engineering phase required before launch

See [PROJECT_IMPLEMENTATION.md](PROJECT_IMPLEMENTATION.md) for detailed implementation status and work items.

---

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
