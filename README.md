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
| Marco Rossi | `marco@bellaitalia.com` | Bella Italia Central | Amsterdam |
| Wei Chen | `wei@goldenlotus.com` | Golden Lotus Amsterdam | Amsterdam |
| Marie Dubois | `marie@jordaanbistro.com` | Jordaan Bistro | Amsterdam |
| Yuki Tanaka | `yuki@sushitokyo.com` | Sushi Tokyo East | Amsterdam |
| Emma de Vries | `emma@healthybowl.nl` | Healthy Bowl Co. | Amsterdam |
| Jake Williams | `jake@burgerpalace.com` | Burger Palace Amsterdam | Amsterdam |
| Raj Patel | `raj@spiceroute.com` | Spice Route India | Amsterdam |
| Priya Sharma | `priya@spicegarden.nl` | Spice Garden Utrecht | Utrecht |
| Carlos Mendoza | `carlos@utrechttaco.nl` | Utrecht Taco Bar | Utrecht |
| **Night Owl Manager** | `owner@nightowl.nl` | **Night Owl Express NL** | **Utrecht** |

### 📱 Customer Accounts
| Name | Email | Location | Special Features |
|------|-------|----------|------------------|
| Test Customer | `test@eatfair.nl` | Central Amsterdam | General testing |
| Piet van Amsterdam | `piet@eatfair.nl` | Amsterdam | Regular customer |
| Emma Janssen | `emma@utrecht.nl` | Utrecht | Utrecht resident |
| Lisa de Vries | `lisa@hetgooi.nl` | Het Gooi | Distance boundary testing |
| Jan de Frequent | `frequent@eatfair.nl` | Amsterdam | **Has test orders in all status states** |
| Sophie Vegano | `vegan@eatfair.nl` | Amsterdam | Dietary preferences testing |
| Multi Address | `multi@eatfair.nl` | Amsterdam | **Multiple addresses**: Work, Holiday Home, Parents' House |

### 🚚 Courier Accounts
| Name | Email | Location | Affiliation |
|------|-------|----------|-------------|
| **Max Speedman** | `courier.max@eatfair.nl` | **Utrecht** | **🌙 Night Owl Express** |
| Lisa Lightning | `courier.lisa@eatfair.nl` | West Amsterdam | General |
| Ahmed Express | `courier.ahmed@eatfair.nl` | East Amsterdam | General |
| Sophie Delivery | `courier.sophie@eatfair.nl` | South Amsterdam | General |
| Utrecht Rider | `courier.utrecht@eatfair.nl` | Central Utrecht | General |
| Snelle Jan | `courier.jan.utrecht@eatfair.nl` | South Utrecht | General |
| **Lisa Lightning** | `lisa.lightning@courier.nightowl.nl` | **Utrecht** | **🌙 Night Owl Express** |

---

## ✅ Verify Login Credentials

To test that you can actually log in with the accounts above:

```bash
# Reset and seed the database with test accounts
mix ecto.reset

# Start the server
mix phx.server
```

Then visit [`localhost:4000`](http://localhost:4000) and try logging in with any of the accounts above.

**Quick Test**: Use `test@eatfair.nl` / `password123456` to verify the customer login works.

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
1. **Login** as `frequent@eatfair.nl`
2. **View order history** - account has orders in all status states
3. **Watch real-time updates** as restaurant updates order status
4. **Test notification system** - events logged for status changes

### Geographic & Address Testing
1. **Login** as `multi@eatfair.nl`
2. **Manage multiple addresses** - Home, Work, Holiday Home, Parents' House
3. **Test delivery radius** - try ordering from different address locations
4. **Distance boundary testing** - restaurants outside radius show "unavailable"

### Review System Testing
1. **Login** as `frequent@eatfair.nl` (has delivered orders)
2. **Submit reviews** - only allowed after order completion
3. **View restaurant ratings** - average ratings update automatically
4. **Test authorization** - cannot review without completing orders

### Night Owl Express Order Processing Testing
**Restaurant Owner**: Night Owl Manager (`owner@nightowl.nl` / `password123456`)

1. **Login** as Night Owl restaurant owner: `owner@nightowl.nl`
2. **Access restaurant dashboard** at `/restaurant/dashboard`
3. **Process incoming orders** at `/restaurant/orders` - Night Owl has extensive order history
4. **Test high-volume order management** - 120+ orders across multiple statuses
5. **Update order statuses** in real-time - customers receive immediate notifications
6. **24/7 operations testing** - Night Owl operates around the clock
7. **Wide delivery coverage** - 49km radius covers most of Netherlands

**Special Features**:
- **24/7 Operations**: All operational hours set to 24/7 (00:00 - 24:00)
- **Nationwide Delivery**: 49km delivery radius for extensive coverage testing
- **High Volume**: 120+ test orders with realistic status distribution
- **Comprehensive Menu**: 5 menu categories with 25+ items
- **Multiple Cuisines**: Late Night, Fast Casual, Pizza, Comfort Food

---

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
