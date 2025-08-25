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

## 🎯 Agent Navigation Guide

*Find exactly what you need, when you need it - this section is automatically available in every conversation.*

### 📋 **I Want To... (Quick Navigation)**

**Plan & Prioritize Work:**
- **What should I work on next?** → [PRIORITIZE_WORK.md](PRIORITIZE_WORK.md) (Master prioritization system)
- **Start feature development** → [START_FEATURE_DEVELOPMENT.md](START_FEATURE_DEVELOPMENT.md) (Auto-determines next feature)
- **Sync documentation** → [SYNC_DOCUMENTATION.md](SYNC_DOCUMENTATION.md) (Update implementation status)

**Understand the Project:**
- **What is EatFair?** → [PROJECT_SPECIFICATION.md](PROJECT_SPECIFICATION.md) (Vision, features, requirements)
- **What's implemented?** → [PROJECT_IMPLEMENTATION.md](PROJECT_IMPLEMENTATION.md) (Progress, test coverage, status)
- **Technical architecture** → [ARCHITECTURAL_DECISION_RECORDS.md](ARCHITECTURAL_DECISION_RECORDS.md) (Design decisions)

**Develop Features:**
- **Phoenix/Elixir patterns** → [AGENTS.md](AGENTS.md) (Development guidelines)
- **Development workflow** → [SOFTWARE_DEVELOPMENT_LIFECYCLE.md](SOFTWARE_DEVELOPMENT_LIFECYCLE.md) (TDD process)
- **Common prompts** → [DEVELOPMENT_PROMPTS.md](DEVELOPMENT_PROMPTS.md) (Code review, debugging, etc.)

### 🤖 Agent Decision Trees

**"I'm starting a new development session"**
```
1. First time on project? → Read PROJECT_SPECIFICATION.md
2. Need current status? → Run: "Sync PROJECT_IMPLEMENTATION.md to actual implementation status"
3. Ready to work? → Use: "Analyze EatFair's current state and recommend next work"
```

**"I want to implement something"**
```
1. Don't know what to build? → Use START_FEATURE_DEVELOPMENT.md prompt
2. Have specific feature? → Follow SOFTWARE_DEVELOPMENT_LIFECYCLE.md TDD process
3. Need technical guidance? → Reference AGENTS.md for Phoenix/Elixir patterns
```

**"Something isn't working"**
```
1. Tests failing? → Use SYNC_DOCUMENTATION.md comprehensive sync
2. Code issues? → Use DEVELOPMENT_PROMPTS.md debugging section
3. Architecture questions? → Check ARCHITECTURAL_DECISION_RECORDS.md
```

**"I need to understand progress"**
```
1. What's done? → Check PROJECT_IMPLEMENTATION.md status
2. Documentation outdated? → Use SYNC_DOCUMENTATION.md one-liner
3. Plan next work? → Use PRIORITIZE_WORK.md master prompt
```

### 📚 Complete Document Catalog

**Core Planning & Strategy:**
- [PROJECT_SPECIFICATION.md](PROJECT_SPECIFICATION.md) - Vision & Requirements (what we're building and why)
- [PROJECT_IMPLEMENTATION.md](PROJECT_IMPLEMENTATION.md) - Progress Tracking (what's done, tested, and working)
- [PRIORITIZE_WORK.md](PRIORITIZE_WORK.md) - Work Prioritization (intelligent task selection system)

**Development Process:**
- [START_FEATURE_DEVELOPMENT.md](START_FEATURE_DEVELOPMENT.md) - Feature Development (auto-determine and implement next feature)
- [SYNC_DOCUMENTATION.md](SYNC_DOCUMENTATION.md) - Documentation Sync (keep docs aligned with reality)
- [SOFTWARE_DEVELOPMENT_LIFECYCLE.md](SOFTWARE_DEVELOPMENT_LIFECYCLE.md) - TDD Workflow (development process and quality standards)
- [DEVELOPMENT_PROMPTS.md](DEVELOPMENT_PROMPTS.md) - Prompt Library (templates for common development tasks)

**Technical Reference:**
- [AGENTS.md](AGENTS.md) - Phoenix/Elixir Patterns (development guidelines for AI agents)
- [ARCHITECTURAL_DECISION_RECORDS.md](ARCHITECTURAL_DECISION_RECORDS.md) - Technical Decisions (architecture choices and reasoning)

**Culture & Context:**
- [DEVELOPMENT_INTERACTION_NOTES.md](DEVELOPMENT_INTERACTION_NOTES.md) - Team Philosophy (development mindset and interaction patterns)
- [RESEARCH_NOTES.md](RESEARCH_NOTES.md) - Research Findings (investigation results and recommendations)

## Development Workflow

### TDD Development Checklist

**CRITICAL**: Always follow this checklist for any development work:

#### 🚀 **Start Phase**
- [ ] Read current status from PROJECT_IMPLEMENTATION.md
- [ ] Create todo list for work (if 3+ steps required)
- [ ] **Add final todo**: "Update PROJECT_IMPLEMENTATION.md with progress"

#### 🔄 **During Development**
- [ ] Write failing tests first
- [ ] Implement minimum code to make tests pass
- [ ] **Update PROJECT_IMPLEMENTATION.md** when significant progress made
- [ ] Refactor while keeping tests green

#### ✅ **Completion Phase** 
- [ ] All tests pass
- [ ] **Update PROJECT_IMPLEMENTATION.md**:
  - [ ] Mark completed features as ✅
  - [ ] Update progress percentages
  - [ ] Update "Current Recommended Work" to next priority
  - [ ] Document any architectural decisions
- [ ] Mark todos as complete

### 🚀 Quick Start Commands (Most Common)

**New to the project?** Start here:
```bash
# First time setup
mix setup
# Navigation guide is built into this WARP.md file (see Agent Navigation Guide above)
```

**Daily development session:**
```
# Use this prompt to get started
"Sync PROJECT_IMPLEMENTATION.md to actual implementation status"
# Then this to determine next work
"Determine and implement the next MVP-critical feature using TDD approach"
```

**Need specific guidance?**
- 🎯 **What to work on**: Use PRIORITIZE_WORK.md master prompt  
- 📋 **Feature development**: Use START_FEATURE_DEVELOPMENT.md prompt
- 🔄 **Documentation sync**: Use SYNC_DOCUMENTATION.md one-liner

## Important Notes

- Always use `mix precommit` before committing changes
- Follow the detailed Phoenix/Elixir guidelines in AGENTS.md for development patterns
- The authentication system uses scopes - access user data via `@current_scope.user`, not `@current_user`
- Prefer LiveView streams over assigns for collections to avoid memory issues
- Use the built-in `<.input>` and `<.icon>` components instead of external alternatives
- **TDD is non-negotiable** - write tests first for every feature
- **Documentation updates are non-negotiable** - PROJECT_IMPLEMENTATION.md must be kept current
- Use the Agent Navigation Guide (above) when you need to find specific project information

## Documentation Workflow

**PROJECT_IMPLEMENTATION.md is the single source of truth** for implementation status and must be updated:

### When to Update
- **During development**: When completing significant milestones or test suites
- **At completion**: When features are fully implemented and tested
- **When blocked**: Document what's preventing progress
- **When pivoting**: Update priorities and current recommended work

### What to Update
- **Test Coverage**: Add new test files and describe what they cover
- **Implementation Status**: Mark features as ✅ Complete, 🟡 In Progress, or 🔴 Missing
- **Progress Tracking**: Update percentages based on actual test coverage
- **Current Recommended Work**: Always point to the next highest priority
- **Technical Notes**: Document architectural decisions and trade-offs

### Update Pattern
```
1. Complete development work
2. Ensure all tests pass
3. Update PROJECT_IMPLEMENTATION.md
4. Commit both code and documentation together
```
