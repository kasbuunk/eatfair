# EatFair Architecture Configuration

**Reference**: This file is referenced from WARP.md and AGENTS.md

This file provides architectural guidance and decision-making frameworks for EatFair development.

## Architectural Design Philosophy

### Core Principles
- **Simplicity Over Complexity**: Choose simple, proven solutions over cutting-edge complexity
- **Community Over Scale**: Optimize for community empowerment rather than massive scale
- **Speed Over Perfection**: MVP excellence through rapid iteration, not perfect architecture
- **Tests Over Documentation**: Executable tests are the primary source of truth
- **User Experience First**: Every technical decision should improve user experience

### Decision-Making Framework
1. **Does it serve the mission?** (Entrepreneur empowerment)
2. **Does it improve user experience?** (Consumers and restaurant owners)
3. **Is it simple to implement and maintain?** (MVP focus)
4. **Does it support fast feedback loops?** (TDD approach)
5. **Is it cost-effective for a donation-based model?** (Lean operations)

## EatFair Architecture Patterns

### Phoenix LiveView Architecture
**Adopted Pattern**: Server-rendered real-time web application
- **Real-time by Default**: Perfect for order tracking, restaurant notifications
- **Single Language**: Elixir for both backend and frontend logic
- **Rapid Development**: No API layer needed, direct database to UI
- **Implementation**: Phoenix v1.8 with `<Layouts.app>` wrappers, LiveView streams

### Database Architecture
**Current**: SQLite for MVP development and deployment
- **Zero Configuration**: No database server setup or management
- **Single File Deployment**: Simplifies backup and migration
- **Migration Path**: PostgreSQL when write concurrency becomes limiting

### Authentication Architecture
**Adopted Pattern**: Scope-based authentication extending `phx.gen.auth`
- **Flexibility**: Easy to add new user types (couriers, admins)
- **Separation of Concerns**: Each user type has dedicated context
- **Implementation**: Use `@current_scope.user` instead of `@current_user`

### Testing Architecture
**Adopted Pattern**: Test-Driven Development (TDD) with end-to-end focus
- **Quality Assurance**: Every feature proven to work through tests
- **Documentation**: Tests serve as executable specifications
- **Fast Feedback**: Test suite completes in <30 seconds

## Architectural Decision Record (ADR) Template

Use this template when making significant architectural decisions:

```markdown
## ADR-###: [Decision Title]

**Status**: [🟡 Proposed | ✅ Adopted | ❌ Rejected | 🔄 Superseded]
**Date**: [YYYY-MM-DD]
**Context**: [Describe the forces at play, including technological, political, social, and project local]

### Decision
[State the architecture decision and provide detailed justification]

### Rationale
- **Reason 1**: [Explanation]
- **Reason 2**: [Explanation]
- **Reason 3**: [Explanation]

### Consequences
- ✅ **Pros**: [Positive consequences]
- ❌ **Cons**: [Negative consequences]
- 🔄 **Mitigations**: [How to address negative consequences]

### Implementation Notes
- [Specific implementation guidance]
- [Key patterns to follow]
- [Migration or rollback considerations]

### Related Decisions
- [Links to related ADRs]
- [Dependencies or conflicts]
```

## Architecture Review Process

### When to Create ADRs
Create ADRs for decisions that:
- **Impact system structure**: Database choice, framework selection, hosting platform
- **Affect user experience**: Authentication approach, real-time updates, mobile strategy
- **Influence development workflow**: Testing approach, deployment strategy, code organization
- **Have long-term consequences**: Technical debt decisions, scalability choices
- **Require team alignment**: Cross-cutting concerns, shared libraries, conventions

### ADR Review Process
1. **Draft ADR**: Use template above, focus on context and rationale
2. **Stakeholder Review**: Get input from affected team members
3. **Decision**: Mark as Adopted, Rejected, or request more information
4. **Implementation**: Update relevant configuration files and documentation
5. **Archive**: Move detailed ADR to `docs/adr/` directory

### Architecture Quality Gates
Before implementing architectural changes:
- [ ] ADR document created and reviewed
- [ ] Implementation impact assessed
- [ ] Migration path documented
- [ ] Rollback strategy defined
- [ ] Team consensus achieved
- [ ] Related documentation updated

## Common Architecture Patterns

### Context Organization
```
lib/eatfair/
├── accounts/          # User management context
├── restaurants/       # Restaurant management context  
├── orders/           # Order processing context
├── payments/         # Payment processing context
└── notifications/    # Notification system context
```

### LiveView Organization
```
lib/eatfair_web/live/
├── user_live/        # User-focused LiveViews
├── restaurant_live/  # Restaurant owner LiveViews
├── order_live/       # Order processing LiveViews
└── components/       # Shared LiveView components
```

### Authentication Flow
```elixir
# Routes requiring authentication
live_session :require_authenticated_user,
  on_mount: [{EatfairWeb.UserAuth, :require_authenticated}] do
  # Authenticated routes
end

# Routes with optional authentication  
live_session :current_user,
  on_mount: [{EatfairWeb.UserAuth, :mount_current_scope}] do
  # Public routes with user context
end
```

### Real-time Architecture
- **Phoenix PubSub**: Order status updates, restaurant notifications
- **LiveView Streams**: Dynamic collections without memory bloat
- **Channel-based**: Real-time order tracking, delivery updates

## Technical Debt Management

### Debt Decision Framework
Document technical debt decisions using ADR process:
- **Context**: Why the shortcut was necessary
- **Impact**: How it might limit future development
- **Resolution Strategy**: Plan for addressing the debt
- **Timeline**: When this needs to be addressed

### Common Technical Debt Areas
- **Database Scaling**: SQLite → PostgreSQL migration planned
- **File Storage**: Local storage → cloud storage migration
- **Search Performance**: Basic queries → search engine integration
- **Mobile Experience**: PWA → native apps consideration

This configuration provides architectural guidance for all EatFair development decisions and should be referenced by prompts like #feature_dev, #debug_bug, and #context_intake.

**Complete ADR History**: See `docs/adr/` directory for full chronology of architectural decisions.
