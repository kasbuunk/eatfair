# Architectural Decision Records (ADRs)

*This document captures key architectural decisions, technical debt, and design philosophy for the EatFair project.*

## Design Philosophy

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

---

## ADR-001: Phoenix LiveView as Primary Frontend Framework

**Status**: ✅ Adopted  
**Date**: Project Inception  
**Context**: Need to choose frontend approach for real-time food ordering platform

### Decision
Use Phoenix LiveView as the primary frontend framework with minimal JavaScript.

### Rationale
- **Real-time by Default**: Perfect for order tracking, restaurant notifications
- **Single Language**: Elixir for both backend and frontend logic
- **Rapid Development**: No API layer needed, direct database to UI
- **SEO Friendly**: Server-rendered HTML with progressive enhancement
- **Community Alignment**: Elixir community values match project mission

### Consequences
- ✅ **Pros**: Fast development, real-time updates, single deployment
- ❌ **Cons**: Limited mobile app options, learning curve for traditional web devs
- 🔄 **Mitigations**: Progressive Web App (PWA) approach for mobile experience

### Implementation Notes
- Use Phoenix v1.8 patterns with `<Layouts.app>` wrappers
- Leverage LiveView streams for performance with collections
- Minimal custom JavaScript, use Phoenix.JS hooks when needed

---

## ADR-002: SQLite for MVP Database

**Status**: ✅ Adopted  
**Date**: Project Inception  
**Context**: Choose database solution balancing simplicity with functionality

### Decision  
Use SQLite for MVP development and initial deployment.

### Rationale
- **Zero Configuration**: No database server setup or management
- **Single File Deployment**: Simplifies backup and migration
- **Phoenix Integration**: Excellent Ecto support via `:ecto_sqlite3`
- **Cost Efficiency**: No database hosting costs for MVP phase
- **Sufficient Scale**: Handles thousands of concurrent users easily

### Consequences
- ✅ **Pros**: Simple deployment, no hosting costs, easy backup/restore
- ❌ **Cons**: Limited concurrent writes, no built-in replication
- 🔄 **Migration Path**: PostgreSQL when write concurrency becomes limiting

### Implementation Notes
- Use Ecto migrations for schema management
- Regular SQLite backups to prevent data loss
- Monitor write contention as user base grows

---

## ADR-003: Scope-Based Authentication System

**Status**: ✅ Adopted  
**Date**: Project Inception  
**Context**: Support multiple user types (consumers, restaurant owners, couriers)

### Decision
Extend `phx.gen.auth` with scope-based authentication rather than role-based.

### Rationale
- **Flexibility**: Easier to add new user types (couriers, admins)
- **Phoenix Integration**: Built on proven `phx.gen.auth` foundation
- **Separation of Concerns**: Each user type has dedicated context
- **Security**: Isolated authentication flows per user type

### Consequences
- ✅ **Pros**: Clear user type separation, extensible architecture
- ❌ **Cons**: More complex than simple role system
- 🔄 **Implementation**: Use `@current_scope.user` instead of `@current_user`

### Implementation Notes
- Scopes defined in `config/config.exs`
- Separate `live_session` blocks for different auth requirements
- Custom login flows per scope as needed

---

## ADR-004: Test-First Development Approach

**Status**: ✅ Adopted  
**Date**: Project Inception  
**Context**: Ensure high-quality, maintainable codebase for mission-critical platform

### Decision
Enforce Test-Driven Development (TDD) for all feature development.

### Rationale
- **Quality Assurance**: Every feature proven to work through tests
- **Documentation**: Tests serve as executable specifications
- **Confidence**: Safe refactoring and feature additions
- **Design**: TDD drives better API design

### Consequences
- ✅ **Pros**: High code quality, living documentation, regression prevention
- ❌ **Cons**: Slower initial development, requires discipline
- 🔄 **Mitigation**: Focus on end-to-end tests over unit tests for speed

### Implementation Notes
- End-to-end tests using Phoenix.LiveViewTest
- Delightful test readability as primary goal
- Fast test suite (< 30 seconds) for quick feedback loops

---

## ADR-005: Fly.io for Hosting and Deployment

**Status**: 🟡 Proposed  
**Date**: Planning Phase  
**Context**: Need cost-effective, Phoenix-friendly hosting solution

### Decision
Deploy to Fly.io for MVP hosting with SQLite database.

### Rationale
- **Phoenix Optimized**: Built-in Phoenix deployment support
- **Global Edge**: Deploy close to users worldwide
- **Cost Effective**: Pay only for actual usage
- **Simple Deployment**: Git-based deployments
- **SQLite Friendly**: Persistent volumes for SQLite databases

### Consequences
- ✅ **Pros**: Low cost, excellent Phoenix support, global deployment
- ❌ **Cons**: Newer platform, limited traditional hosting features
- 🔄 **Alternatives**: Evaluate Heroku, Railway, or DigitalOcean if needed

### Implementation Notes
- Use persistent volumes for SQLite storage
- Configure automated deployments from main branch
- Set up staging and production environments

---

## ADR-006: Payment Processing Strategy

**Status**: 🟡 Proposed  
**Date**: Planning Phase  
**Context**: Handle payments while maintaining zero-commission promise

### Decision
Integrate with Stripe for payment processing, restaurant owners pay only Stripe fees.

### Rationale
- **Industry Standard**: Well-established, trusted payment processor
- **Phoenix Integration**: Excellent Elixir libraries available
- **Transparent Fees**: Clear fee structure (2.9% + 30¢)
- **Global Support**: Works in target markets (Europe, North America)
- **Developer Experience**: Great APIs and documentation

### Consequences
- ✅ **Pros**: Reliable payments, clear fee structure, good integration
- ❌ **Cons**: Payment processing fees still apply (not platform's fault)
- 🔄 **Future**: Research lower-cost payment processors

### Implementation Notes
- Direct charges to restaurant bank accounts (no platform middleman)
- Clear fee disclosure to restaurant owners
- Support for future cryptocurrency payments

---

## ADR-007: Location Services Implementation

**Status**: 🟡 Proposed  
**Date**: Planning Phase  
**Context**: Restaurant discovery and delivery zone management

### Decision
Use browser geolocation API with optional address input fallback.

### Rationale
- **User Experience**: Automatic location detection for convenience
- **Privacy Friendly**: User controls location sharing
- **Cost Effective**: No external API costs for basic geolocation
- **Fallback Support**: Manual address entry for privacy-conscious users

### Consequences
- ✅ **Pros**: Good UX, no API costs, privacy-respecting
- ❌ **Cons**: Depends on user permission, accuracy varies
- 🔄 **Enhancement**: Add mapping service integration later if needed

### Implementation Notes
- JavaScript geolocation API integration
- Address validation and geocoding for manual entry
- Restaurant delivery zone polygon support

---

## ADR-008: Image and File Storage

**Status**: 🟡 Proposed  
**Date**: Planning Phase  
**Context**: Restaurant photos, menu images, and user uploads

### Decision
Local file storage for MVP, cloud storage for production scale.

### Rationale
- **MVP Simplicity**: No cloud service setup or costs initially
- **Phoenix Integration**: Easy file serving with Phoenix static assets
- **Cost Control**: No storage costs during MVP validation
- **Migration Ready**: Easy transition to cloud storage when needed

### Consequences
- ✅ **Pros**: Simple setup, no external dependencies, cost-free
- ❌ **Cons**: Not scalable, no CDN benefits, backup complexity
- 🔄 **Migration**: Move to AWS S3 or similar when scaling

### Implementation Notes
- Organized file structure in `priv/static/uploads/`
- Image resizing and optimization on upload
- Clear migration path to cloud storage

---

## ADR-009: Real-Time Communication Strategy

**Status**: ✅ Adopted  
**Date**: Project Inception  
**Context**: Order status updates, restaurant notifications, delivery tracking

### Decision
Use Phoenix Channels through LiveView for all real-time communication.

### Rationale
- **Built-in Solution**: Native Phoenix real-time capabilities
- **LiveView Integration**: Seamless real-time UI updates
- **WebSocket Fallback**: Graceful degradation to long-polling
- **Scalability**: Phoenix handles thousands of concurrent connections

### Consequences
- ✅ **Pros**: No external services, excellent integration, scalable
- ❌ **Cons**: Requires persistent connections, complexity for mobile
- 🔄 **Enhancement**: Push notifications for mobile apps later

### Implementation Notes
- Order status broadcasts via PubSub
- Restaurant dashboard real-time order updates
- Customer order tracking without page refreshes

---

## ADR-010: Code Quality and Formatting

**Status**: ✅ Adopted  
**Date**: Project Inception  
**Context**: Maintain consistent, high-quality codebase

### Decision
Enforce strict code quality standards with automated tooling.

### Rationale
- **Consistency**: Uniform code style across entire project
- **Quality**: Zero warnings policy prevents technical debt
- **Automation**: Reduce manual code review burden
- **Standards**: Follow Elixir community best practices

### Consequences
- ✅ **Pros**: Consistent codebase, fewer bugs, easier maintenance
- ❌ **Cons**: Stricter development process, learning curve
- 🔄 **Tools**: `mix precommit` runs all quality checks

### Implementation Notes
- `mix format` for automatic code formatting
- `mix compile --warning-as-errors` for zero warnings
- `mix deps.unlock --unused` for dependency management
- Custom `.formatter.exs` configuration

---

## Technical Debt Registry

### Current Technical Debt
1. **Database Scaling**: SQLite will need PostgreSQL migration at scale
2. **File Storage**: Local storage needs cloud migration for production
3. **Search Performance**: Basic Ecto queries will need search engine at scale
4. **Mobile Experience**: PWA approach may need native apps eventually

### Debt Management Strategy
- **Document Early**: Record all technical debt decisions
- **Monitor Metrics**: Track when debt becomes limiting
- **Plan Migration**: Always have next step planned
- **Gradual Transition**: Minimize disruption during debt resolution

---

## Coding Conventions

### Naming Conventions
- **Modules**: PascalCase (`EatfairWeb.RestaurantLive`)
- **Functions**: snake_case (`create_restaurant/1`)
- **Variables**: snake_case (`restaurant_id`)
- **Atoms**: snake_case (`:order_confirmed`)

### File Organization
- **Contexts**: `lib/eatfair/context_name/`
- **LiveViews**: `lib/eatfair_web/live/context_name/`
- **Tests**: Mirror production structure in `test/`
- **Components**: `lib/eatfair_web/components/`

### Documentation Standards
- **Module Docs**: Purpose and usage overview
- **Function Docs**: Parameters, return values, examples
- **Test Descriptions**: Clear user story format
- **Code Comments**: Only for complex business logic

---

## Future Considerations

### Scaling Decision Points
- **1,000+ Daily Orders**: Consider PostgreSQL migration
- **10+ Cities**: Need CDN and cloud storage
- **100+ Restaurants**: Search engine integration  
- **Mobile Usage > 70%**: Native mobile apps

### Technology Evolution
- **Payment Processing**: Monitor cryptocurrency payment adoption
- **Real-time**: Evaluate WebRTC for advanced features
- **AI Integration**: Restaurant recommendation engines
- **Analytics**: Self-hosted analytics platform

---

*This document is updated when significant architectural decisions are made. All decisions should align with the project's mission of empowering local restaurant entrepreneurs.*
