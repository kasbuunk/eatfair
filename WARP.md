# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

Eatfair is a Phoenix web application built with Phoenix v1.8, using Elixir and SQLite. The application includes user authentication (via phx.gen.auth) and appears to be designed for restaurant/cuisine functionality based on the migrations.

## Development Commands

### Setup and Dependencies
```bash
mix setup                    # Install dependencies, setup database, and build assets
mix deps.get                # Install dependencies only
```

### Development Server
```bash
mix phx.server              # Start Phoenix server at localhost:4000
iex -S mix phx.server       # Start with interactive Elixir shell
```

### Database Operations
```bash
mix ecto.create             # Create database
mix ecto.migrate            # Run migrations
mix ecto.reset              # Drop and recreate database with seeds
mix ecto.setup              # Create, migrate, and seed database
```

### Testing
```bash
mix test                    # Run all tests
mix test test/my_test.exs   # Run specific test file
mix test --failed           # Run only previously failed tests
```

### Code Quality
```bash
mix precommit               # Run all pre-commit checks (compile with warnings as errors, unlock unused deps, format, test)
mix compile --warning-as-errors  # Compile with warnings as errors
mix format                  # Format code
mix deps.unlock --unused    # Unlock unused dependencies
```

### Assets
```bash
mix assets.setup            # Install Tailwind and esbuild if missing
mix assets.build            # Build assets for development
mix assets.deploy           # Build and minify assets for production
```

## Architecture

### Application Structure
- **Eatfair**: Main OTP application context
  - `Eatfair.Accounts`: User authentication and management
  - `Eatfair.Repo`: Ecto repository for database operations
  - `Eatfair.Mailer`: Email functionality using Swoosh

- **EatfairWeb**: Web interface layer
  - Uses Phoenix LiveView heavily with v1.8 patterns
  - Authentication handled via `EatfairWeb.UserAuth` with scope-based authorization
  - Core UI components in `EatfairWeb.CoreComponents`

### Authentication System
The app uses a custom scope-based authentication system built on top of phx.gen.auth:
- Scopes defined in `config/config.exs` with user scope as default
- Routes organized into `live_session` blocks for authentication requirements:
  - `:current_user` - Routes that work with or without authentication
  - `:require_authenticated_user` - Routes requiring logged-in users
- Uses `@current_scope.user` instead of `@current_user` in templates

### Database
- Uses SQLite (`:ecto_sqlite3`) with Ecto
- Migrations include user authentication tables and restaurants/cuisines functionality
- Auto-migration on application start in releases

### Frontend Stack
- Tailwind CSS for styling (v4.1.7)
- esbuild for JavaScript bundling (v0.25.4)  
- Heroicons for icons via `<.icon>` component
- LiveView for interactive UI with HEEx templates

### Key Conventions
- All LiveViews follow Phoenix v1.8 patterns with `<Layouts.app>` wrapper
- Forms use `to_form/2` assigns with `<.form>` and `<.input>` components
- HTTP requests use `:req` library (included by default)
- LiveView streams for collections instead of assigns to prevent memory issues

### Configuration
- Environment-specific configs in `config/` directory
- Custom scope configuration for authentication system
- Asset compilation configured for both development and production

### Testing
- Uses `Phoenix.LiveViewTest` and `LazyHTML` for testing
- Test database automatically created and migrated before test runs
- Focused on testing element presence and interactions rather than raw HTML

## Project Documentation

This project follows a comprehensive documentation-driven development approach:

- **[DOCUMENT_INDEX.md](DOCUMENT_INDEX.md)** - Quick reference to all project documents
- **[PROJECT_SPECIFICATION.md](PROJECT_SPECIFICATION.md)** - Vision, mission, and feature requirements  
- **[PROJECT_IMPLEMENTATION.md](PROJECT_IMPLEMENTATION.md)** - Current progress and test coverage status
- **[SOFTWARE_DEVELOPMENT_LIFECYCLE.md](SOFTWARE_DEVELOPMENT_LIFECYCLE.md)** - TDD workflow and quality standards
- **[DEVELOPMENT_PROMPTS.md](DEVELOPMENT_PROMPTS.md)** - Reusable prompts for common development tasks

## Development Workflow

### Start Feature Development (Quick Prompt)
**Use this prompt when you want to make progress without specifying what to work on:**

```
Review the current project status and determine the next best feature to implement.

PROCESS:
1. Check PROJECT_IMPLEMENTATION.md for current progress
2. Identify highest priority missing MVP feature
3. Review PROJECT_SPECIFICATION.md to understand requirements
4. Suggest specific feature to implement next
5. Justify why this feature should be prioritized
6. Propose TDD approach and test strategy

OUTPUT:
- Current project status summary
- Recommended next feature with justification
- Detailed test-first implementation approach
- Success criteria and acceptance tests
```

## Important Notes

- Always use `mix precommit` before committing changes
- Follow the detailed Phoenix/Elixir guidelines in AGENTS.md for development patterns
- The authentication system uses scopes - access user data via `@current_scope.user`, not `@current_user`
- Prefer LiveView streams over assigns for collections to avoid memory issues
- Use the built-in `<.input>` and `<.icon>` components instead of external alternatives
- **TDD is non-negotiable** - write tests first for every feature
- Reference DOCUMENT_INDEX.md when you need to find specific project information
