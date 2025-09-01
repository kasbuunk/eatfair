# EatFair Agent Workflows Configuration

**Project**: EatFair  
**Last Updated**: 2025-09-01

## Overview
EatFair-specific agent configurations, specialization areas, and workflow patterns.

## EatFair Technology Specialization Areas

### Phoenix LiveView Development
- **Authentication Flows**: Phoenix.gen.auth with scope-based authorization patterns
- **Component Architecture**: Built-in `<.input>` and `<.icon>` components from core_components.ex
- **Template Systems**: HEEx templates (.html.heex files) exclusively
- **Memory Management**: Stream-based data handling for collections

### Database and Schema Management  
- **ORM Patterns**: Ecto with standard Phoenix context patterns
- **Schema Design**: Geographic data (lat/lng), status tracking, financial fields
- **Migration Strategy**: Standard Ecto migrations with comprehensive seed data
- **Performance**: SQLite optimization for MVP scale

### EatFair Business Domain Specialization

### Core Business Entities
- **User Management**: Multi-role system (customers, restaurant owners, couriers)
- **Restaurant Operations**: Geographic search, cuisine categorization, delivery radius management
- **Order Processing**: Status tracking, payment processing, delivery coordination
- **Platform Features**: Reviews, favorites, notifications, analytics

### Geographic and Location Services
- **Delivery Radius**: Precise coordinate-based delivery area calculation
- **Restaurant Discovery**: Location-based search with distance calculations  
- **Route Optimization**: Efficient delivery logistics for couriers

### Quality Gates Specific to EatFair

### Testing Requirements
- **Full Test Suite**: Must complete in <30 seconds for rapid development cycles
- **LiveView Testing**: Phoenix.LiveViewTest for UI interaction validation
- **Geographic Testing**: Location-based feature validation with test coordinates
- **Authentication Testing**: Multi-role authentication flow validation

### Performance Standards
- **Database**: SQLite performance optimization for geographic queries
- **UI Responsiveness**: LiveView real-time updates without memory leaks
- **Mobile Compatibility**: Touch-friendly interfaces for delivery app usage

### Documentation Requirements  
When completing EatFair features:
1. Update `documentation/legacy_implementation_log.md` with progress
2. Mark features as ✅ Complete with test file references
3. Update overall MVP progress percentage
4. Document any architectural decisions in ADRs

## Agent Interaction Patterns for EatFair

### Development Workflow Integration
- **Backlog Integration**: All work must update EatFair priority system
- **Progress Tracking**: Implementation status tracked in project documentation
- **Quality Validation**: Phoenix/Elixir specific quality gates before completion

### Cross-Role Coordination
- **Restaurant Onboarding**: Coordination between user management and restaurant contexts
- **Order Fulfillment**: Integration across users, restaurants, and courier workflows  
- **Payment Processing**: Financial data handling with audit trail requirements

## Related Generic Prompts
This configuration enhances:
- All `prompts/tasks/` files with EatFair business context
- `prompts/tasks/feature_dev.md` with Phoenix LiveView patterns
- `prompts/tasks/debug_bug.md` with Elixir/Phoenix debugging approaches
- `prompts/tasks/test_author.md` with LiveView testing patterns
