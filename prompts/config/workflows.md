# EatFair Development Workflows

**Reference**: This file is referenced from WARP.md and AGENTS.md

This file provides EatFair-specific workflow configurations and processes that implement the universal principles defined in WARP.md.

## Development Workflow Configuration

### Test-Driven Development (TDD) Workflow
**EatFair follows strict TDD principles:**
1. **Red**: Write failing test that describes desired behavior
2. **Green**: Write minimal code to make test pass  
3. **Refactor**: Improve code while keeping tests green
4. **Update**: Update backlog item status and documentation

### Quality Gates (mix precommit)
All code changes must pass these gates:
```bash
mix test                              # All tests pass
mix format                           # Code formatting
mix compile --warnings-as-errors     # No compilation warnings
mix credo                           # Static analysis
mix deps.audit                      # Security audit
```

### Documentation Updates
**Required documentation updates:**
- **Feature completion**: Update `documentation/legacy_implementation_log.md`
- **Architectural changes**: Document in `documentation/architectural_decision_records.md`
- **Progress tracking**: Mark backlog items as #status/done when complete
- **Specification changes**: Update `documentation/product_specification.md`

## Backlog Management Process

### Status Tags
- `#status/todo` - Not yet started
- `#status/in_progress` - Currently being worked on  
- `#status/blocked` - Waiting on external dependencies
- `#status/done` - Meets all Definition of Done criteria

### Priority Management
- **Single source of truth**: `backlog_dashboard.md` priority order
- **Update triggers**: When completing work, getting blocked, or priorities change
- **New work**: Create detailed specifications in `backlog/` directory

### Work Item Creation
**When to create backlog items:**
- User requests "extensive" or "comprehensive" implementation
- Work estimated at 3+ days effort
- Cross-team coordination required
- Architectural decisions needed

**Backlog item format:**
```
backlog/YYYYMMDDHHMMSS_descriptive_name.md
- Status: #status/todo
- Priority: High/Medium/Low  
- Estimated Effort: Hours or days
- Dependencies: Other work or external factors
```

## Change Management

### Quick Fix Criteria
Changes qualify as #quick_fix when:
- Configuration or content changes only
- Single file modifications
- No new business logic
- Reversible without data loss
- Test coverage exists for affected functionality

### Feature Development Approval
Requires product owner approval for:
- New user-facing functionality
- Changes to core business logic
- Database schema modifications
- External service integrations
- API endpoint changes

### Emergency Response
**Production incidents (#incident_resp):**
1. Immediate assessment and impact evaluation
2. Stakeholder notification (restaurant owners, consumers affected)
3. Quick mitigation using #quick_fix if possible
4. Full #debug_bug process for root cause analysis
5. Post-incident review and prevention measures

## Communication Protocols

### Stakeholder Updates
**Restaurant owners (primary users):**
- Feature announcements via in-app notifications
- Service disruption alerts with estimated resolution time
- Revenue impact communications during outages

**Internal team updates:**
- Daily progress in standup format
- Weekly backlog priority reviews
- Monthly architectural decision reviews

### Documentation Standards
**Code comments:**
- Business logic explanations for complex calculations
- Phoenix/LiveView pattern explanations for team education
- Database schema relationship explanations

**Commit messages:**
- Conventional format: `type(scope): description`
- Include backlog item reference when applicable
- Explain "why" not just "what" in commit body

## Technology-Specific Workflows

### Phoenix LiveView Development
1. **Component first**: Build reusable components before pages
2. **State management**: Use streams for collections, assigns for simple state
3. **Real-time features**: Leverage LiveView's real-time capabilities over external solutions
4. **Authentication**: Always use `@current_scope.user`, never `@current_user`

### Database Changes
1. **Migrations**: Create reversible migrations with proper rollback procedures
2. **Seed data**: Update seeds to reflect schema changes
3. **Test data**: Ensure test fixtures work with new schema
4. **Documentation**: Update ERD and schema documentation

### Testing Patterns
1. **End-to-end first**: Focus on user journey testing over unit tests
2. **Phoenix LiveView testing**: Use `Phoenix.LiveViewTest` patterns
3. **Fast execution**: Target <30 seconds for full test suite
4. **Realistic data**: Use enhanced seed data for complex scenarios

## Contributor Interaction Guidelines

### Development Philosophy
**MVP Excellence Approach**: Build the minimum excellent product - the smallest thing that delivers exceptional value to users.

### Communication Style
- **Be Direct**: Focus on work outcomes, skip pleasantries
- **Question Assumptions**: Challenge decisions that don't serve the mission
- **Share Context**: Always explain the "why" behind suggestions
- **Stay Mission-Focused**: Connect decisions back to entrepreneur empowerment
- **Avoid Sycophancy**: Direct, honest feedback leads to better outcomes

### Decision Framework
1. **Does this improve user experience?** → Do it
2. **Does this add complexity without clear value?** → Skip it
3. **Can we test this easily?** → If no, simplify first
4. **Will users notice if this is missing?** → If no, deprioritize

### Development Cycle Speed Goals
Minimize time from "idea" to "validated working feature":
1. **Idea** → **Test** (< 5 minutes)
2. **Test** → **Implementation** (< 30 minutes) 
3. **Implementation** → **Working Feature** (< 2 hours)
4. **Feature** → **User Feedback** (< 1 day)

### Effective Interaction Patterns

#### Feature Development
1. **Start with Specification**: Ensure alignment with project requirements
2. **Write the Test**: Clear, readable test describing user journey
3. **Implement Minimally**: Smallest code change to make test pass
4. **Refactor for Quality**: Improve design while keeping tests green
5. **Update Progress**: Mark feature complete in tracking systems

#### Problem Solving
1. **Reproduce Issue**: Create test demonstrating the problem
2. **Understand Root Cause**: Fix underlying issues, not symptoms
3. **Simple Solution First**: Try simplest fix before complex ones
4. **Verify Fix**: Ensure test passes with no regressions
5. **Document Learning**: Capture insights for future reference

### Anti-Patterns to Avoid
- **Feature Creep**: Stick to MVP scope, resist "nice to have" features
- **Over-Engineering**: Choose simple solutions that work over complex theoretical ones
- **Quality Shortcuts**: Never skip quality gates to save time
- **Analysis Paralysis**: Make reversible decisions quickly
- **Documentation Lag**: Update progress tracking immediately after features

This configuration applies to all EatFair development work and should be referenced by relevant prompts.
