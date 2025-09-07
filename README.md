# EatFair

A commission-free food delivery platform that empowers local restaurant entrepreneurs.

## 🎯 Using EatFair's Tag-Based Development System

EatFair uses a sophisticated tag-based prompt system for efficient development. Here are the most important workflows:

### 🚀 Main Development Workflows

#### Feature Development
```bash
# Implement complete new features using TDD methodology
Use #feature_dev to implement user notification preferences system
Use #feature_dev to add restaurant analytics dashboard
Use #feature_dev to implement real-time order tracking
```

#### Bug Resolution
```bash
# Systematically debug and fix issues
Use #debug_bug to fix payment calculation errors
Use #debug_bug to resolve location search crashes
Use #debug_bug to fix mobile checkout failures
```

#### Product Strategy & Planning
```bash
# Plan features and prioritize development work
Use #product_strategy to plan Q2 feature roadmap
Use #product_strategy to evaluate new restaurant onboarding flow
Use #product_strategy to prioritize mobile app vs web improvements
```

#### User Support & Feedback
```bash
# Process customer feedback and support requests
Use #support_triage to handle restaurant owner checkout complaints
Use #support_triage to process consumer delivery time feedback
Use #support_triage to investigate payment processing issues
```

#### Quality & Testing
```bash
# Ensure comprehensive test coverage and quality
Use #test_author to create comprehensive payment system tests
Use #test_author to add end-to-end restaurant onboarding tests
Use #code_review to evaluate authentication system changes
```

### 🧩 Building Block Composition

#### Sequential Workflows
```bash
# Chain building blocks for complex work
Apply #context_intake then #test_plan then #feature_dev for order tracking
Use #context_intake then #create_repro then #debug_bug for checkout issues
Apply #test_plan then #write_tests then #run_all_tests for payment validation
```

#### EatFair-Specific Examples
```bash
# Restaurant owner workflows
Use #feature_dev to implement menu bulk upload for restaurant efficiency
Use #debug_bug to fix delivery radius calculation affecting restaurant visibility

# Consumer experience workflows  
Use #feature_dev to add restaurant favorites and order history
Use #support_triage to handle consumer complaints about delivery times

# Business logic workflows
Use #test_author to ensure zero commission calculations are bulletproof
Use #debug_bug to fix location-based restaurant discovery accuracy
```

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

### Development Guidelines

```bash
# Check what to work on next
Use #product_strategy to determine current priorities

# Start new feature development
Use #feature_dev to implement the next priority feature

# Fix any issues that arise
Use #debug_bug to systematically resolve problems

# Ensure quality before committing
Use #run_all_tests to validate all functionality works
```

## 👤 Test User Accounts

*All accounts use password: `password123456`*

### 🍽️ Restaurant Owners
| Name | Email | Restaurant | Location |
|------|-------|------------|----------|
| Marco Rossi | `marco@bellaitalia.com` | Bella Italia Central | Amsterdam |
| Wei Chen | `wei@goldenlotus.com` | Golden Lotus Amsterdam | Amsterdam |
| Marie Dubois | `marie@jordaanbistro.com` | Jordaan Bistro | Amsterdam |
| Yuki Tanaka | `yuki@sushitokyo.com` | Sushi Tokyo East | Amsterdam |
| **Night Owl Manager** | `owner@nightowl.nl` | **Night Owl Express NL** | **Utrecht** |

### 📱 Customer Accounts
| Name | Email | Location | Special Features |
|------|-------|----------|------------------|
| Test Customer | `test@eatfair.nl` | Central Amsterdam | General testing |
| Jan de Frequent | `frequent@eatfair.nl` | Amsterdam | **Has test orders in all status states** |
| Multi Address | `multi@eatfair.nl` | Amsterdam | **Multiple addresses**: Work, Holiday Home, Parents' House |

### 🚚 Courier Accounts
| Name | Email | Location | Affiliation |
|------|-------|----------|-------------|
| **Max Speedman** | `courier.max@eatfair.nl` | **Utrecht** | **🌙 Night Owl Express** |
| Lisa Lightning | `courier.lisa@eatfair.nl` | West Amsterdam | General |

### 👑 Admin Accounts
*These accounts have elevated privileges for platform administration and should be used with caution.*

*Admin accounts use different passwords for security:*
- `admin@eatfair.nl`: `admin123456789`
- `support@eatfair.nl`: `support123456789`  
- `sysadmin@eatfair.nl`: `sysadmin123456789`

| Name | Email | Role | Special Access |
|------|-------|------|----------------|
| **Admin User** | `admin@eatfair.nl` | **System Administrator** | **Full platform oversight** |
| Support Manager | `support@eatfair.nl` | Support Administrator | User feedback and issue management |
| System Administrator | `sysadmin@eatfair.nl` | Technical Administrator | Backend system management |

## 🧪 Testing & Development

### Running Tests
```bash
# Run all tests (163 tests, ~0.9 seconds)
mix test

# Run tests with detailed output
mix test --trace

# Run only failed tests
mix test --failed
```

### Test Data Scripts
```bash
# Basic seed data (all restaurants, users, menus)
mix run priv/repo/seeds.exs

# Comprehensive Night Owl test data (29 orders across ALL delivery stages)
mix run priv/repo/night_owl_test_orders.exs
```

**Night Owl Test Data** creates orders for manual testing of:
- **All 9 order statuses**: `pending` → `confirmed` → `preparing` → `ready` → `out_for_delivery` → `delivered` + edge cases (`cancelled`, `rejected`, `delivery_failed`)
- **Complete delivery lifecycle**: Order placement → Restaurant processing → Courier assignment → Live tracking → Completion
- **Historical data**: 15 delivered orders spanning 30 days + failed orders for pagination testing
- **Real relationships**: Customer (`test@eatfair.nl`) ↔ Restaurant (`Night Owl Express NL`) ↔ Courier (`courier.max@eatfair.nl`)

### Code Quality Checks
```bash
# Run all pre-commit checks (compile with warnings as errors, format, test)
mix precommit

# Individual quality checks
mix compile --warnings-as-errors  # Check for warnings
mix format                         # Format code
```

### Database Operations
```bash
# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Run migrations
mix ecto.migrate
```

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

### Admin Dashboard Experience
1. **Login** as `admin@eatfair.nl` (or other admin account)
2. **Access admin dashboard** at `/admin/dashboard` 
3. **Monitor platform metrics** - users, restaurants, orders, revenue
4. **Review user feedback** at `/admin/feedback` - process support requests
5. **Manage user accounts** at `/admin/users` - user roles and verification
6. **Monitor community impact** - track zero-commission mission success

## 📚 Documentation & Development System

- **[Development Guide](AGENTS.md)**: Complete prompt system documentation and usage patterns
- **[Product Specification](prompts/product_specification.md)**: Complete feature requirements and user journeys

## Contributing

EatFair follows strict Test-Driven Development practices with a comprehensive prompt system for efficient development.

### Core Development Principles

- **TDD Required**: Use `#feature_dev` for all new functionality - tests first, always
- **Prompt-Driven Development**: Use tags like `#debug_bug`, `#test_author` for systematic workflows
- **Documentation Discipline**: All prompts automatically update project documentation
- **Zero Commission Mission**: All features must support the commission-free model
- **Quality Excellence**: Every prompt includes quality gates and validation steps

### Getting Started with Development

1. **Understand the system**: `Use #code_orient to understand EatFair's architecture`
2. **Set up environment**: `Use #env_setup to establish development environment`
3. **Pick up work**: `Use #product_strategy to identify next priority`
4. **Implement features**: `Use #feature_dev following TDD principles`
5. **Maintain quality**: `Use #run_all_tests and #code_review before committing`

## Mission

EatFair exists to create a more equitable food delivery ecosystem where:

- Restaurant entrepreneurs can build sustainable businesses
- Consumers get great food at fair prices  
- Local communities thrive through supporting neighborhood businesses
- Technology serves people rather than extracting value from them

By taking zero commission, EatFair proves that technology platforms can create value for all stakeholders without exploiting small business owners.

## Technology Stack

- **Backend**: Phoenix/Elixir with LiveView for real-time features
- **Database**: SQLite (appropriate for current MVP scale)
- **Authentication**: Phoenix generated auth with scope-based authorization
- **UI**: Phoenix LiveView components with TailwindCSS styling
- **Testing**: ExUnit with Phoenix.LiveViewTest for comprehensive coverage

## Learn More

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
