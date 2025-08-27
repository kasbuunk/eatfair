# System Constitution (WARP)

This document defines the global principles and operational rules that govern our entire development system. These principles are universal and must be followed by all agents, regardless of their specialized role.

## Core Development Principles

### 1. Atomic Commits
**Principle**: Every commit represents a single, complete, and logical unit of work.

**Rules**:
- Commits must be self-contained and not break the build
- Each commit message must clearly describe what was changed and why
- Use conventional commit format: `type(scope): description`
- Never commit incomplete features or broken tests

**Quality Gates**:
- All tests must pass before commit
- Code must compile without warnings
- Documentation must be updated to reflect changes

### 2. Test-Driven Development (TDD)
**Principle**: Tests are written before implementation code and drive the design.

**Rules**:
- **Red**: Write a failing test that defines the desired behavior
- **Green**: Write the minimal code to make the test pass
- **Refactor**: Improve the code while keeping tests green
- Never skip the failing test step
- Test coverage must be maintained or improved with each change

### 3. Single Source of Truth
**Principle**: Each piece of information has one authoritative location.

**Rules**:
- The [Backlog Dashboard](../backlog_dashboard.md) is the single source of truth for work prioritization
- The [Development Log](../documentation/development_log.md) is the single source of truth for progress tracking
- The [Definition of Done](../documentation/definition_of_done.md) defines completion criteria
- Avoid duplicating information across multiple documents

### 4. Continuous Integration
**Principle**: Changes are integrated frequently and validated automatically.

**Rules**:
- Use `mix precommit` before every commit to validate changes
- All quality gates must pass before merging
- Broken builds must be fixed immediately
- Changes should be small, frequent, and incremental

## Operational Rules

### Information Architecture
**Directory Structure**:
- `documentation/` - Authoritative project documentation
- `prompts/` - Agent prompts and workflow definitions  
- `backlog/` - Individual backlog items with detailed specifications
- `backlog_dashboard.md` - Ordered priority list (single source of truth)

**Naming Conventions**:
- All directories and markdown files use `lowercase_with_underscores`
- File names should be descriptive and indicate their purpose
- Avoid abbreviations unless they are widely understood

### Status Management
**Status Tags**: All backlog items must have one status tag:
- `#status/todo` - Not yet started
- `#status/in_progress` - Currently being worked on
- `#status/blocked` - Waiting on external dependencies
- `#status/done` - Meets all Definition of Done criteria

**Priority Order**: The order of items in the [Backlog Dashboard](../backlog_dashboard.md) defines their priority. No other priority indicators are needed.

### Documentation Requirements
**Living Documentation**: Documentation must always reflect the current state of the system.

**Update Triggers**:
- When completing features or major milestones
- When architectural decisions are made
- When blockers are encountered or resolved
- When priorities change

**Quality Standards**:
- Documentation must be actionable and specific
- Include context and reasoning, not just facts
- Link to related documents to maintain coherence
- Use consistent formatting and structure

## Agent Coordination Rules

### Work Assignment
- The **Orchestrator Agent** assigns work based on agent capabilities and current priorities
- Agents must not self-assign work outside their designated capabilities
- All work must be tracked through the established workflow

### Handoff Protocols
- Clear handoff points between different agent types
- All necessary context must be documented before handoff
- Quality gates must be verified before passing work to the next agent

### Feedback Loops
- Regular retrospectives to improve processes and workflows
- Immediate feedback on quality issues or process violations
- Continuous refinement of prompts and procedures based on learning

## Quality Assurance

### Code Quality
- Follow established patterns and conventions (see [Technical Reference](../documentation/phoenix_elixir_reference.md))
- Maintain or improve test coverage with each change
- Use static analysis tools and linting
- Address technical debt proactively

### Process Quality
- All changes must follow the established workflow
- Documentation must be updated concurrently with code changes
- Quality gates cannot be bypassed
- Process improvements must be discussed and agreed upon

### Communication
- All important decisions must be documented
- Context and reasoning should be preserved for future reference
- Clear, concise communication in all documentation
- Regular status updates and progress tracking

## Self-Improvement Loop

### Learning Integration
**Principle**: The system continuously improves based on experience and feedback.

**Process**:
1. **Observe** - Monitor outcomes and identify areas for improvement
2. **Analyze** - Understand root causes and patterns
3. **Adjust** - Make targeted improvements to processes or procedures
4. **Validate** - Measure the impact of changes
5. **Document** - Capture learnings for future reference

### Feedback Sources
- Development velocity and quality metrics
- Agent performance and collaboration effectiveness
- User feedback and business value delivery
- Technical debt accumulation and resolution

## Emergency Protocols

### Build Failures
- Immediate priority to restore green build state
- All other work stops until build is fixed
- Root cause analysis and prevention measures

### Blocking Issues
- Clear escalation path for unresolvable blockers
- Alternative work identification while blockers are resolved
- Documentation of blocker impact and resolution

### Quality Regressions
- Immediate rollback if quality standards are not met
- Investigation and remediation before proceeding
- Process improvements to prevent recurrence

## 🎯 Agent Navigation Guide

*Find exactly what you need, when you need it - this section is automatically available in every conversation.*

### 📋 **I Want To... (Quick Navigation)**

**Plan & Prioritize Work:**
- **What should I work on next?** → [prioritize_work.md](prioritize_work.md) (Master prioritization system)
- **Start feature development** → [start_feature_development.md](start_feature_development.md) (Auto-determines next feature)
- **Sync documentation** → [sync_documentation.md](sync_documentation.md) (Update implementation status)

**Understand the Project:**
- **What is EatFair?** → [product_specification.md](../documentation/product_specification.md) (Vision, features, requirements)
- **What's implemented?** → [legacy_implementation_log.md](../documentation/legacy_implementation_log.md) (Progress, test coverage, status)
- **Technical architecture** → [architectural_decision_records.md](../documentation/architectural_decision_records.md) (Design decisions)

**Develop Features:**
- **Phoenix/Elixir patterns** → [agents.md](agents.md) (Development guidelines)
- **Development workflow** → [software_development_lifecycle.md](software_development_lifecycle.md) (TDD process)
- **Common prompts** → [development_prompts.md](development_prompts.md) (Code review, debugging, etc.)

### 🤖 Agent Decision Trees

**"I'm starting a new development session"**
```
1. First time on project? → Read product_specification.md
2. Need current status? → Run: "Sync legacy_implementation_log.md to actual implementation status"
3. Ready to work? → Use: "Analyze EatFair's current state and recommend next work"
```

**"I want to implement something"**
```
1. Don't know what to build? → Use start_feature_development.md prompt
2. Have specific feature? → Follow software_development_lifecycle.md TDD process
3. Need technical guidance? → Reference agents.md for Phoenix/Elixir patterns
```

**"Something isn't working"**
```
1. Tests failing? → Use sync_documentation.md comprehensive sync
2. Code issues? → Use development_prompts.md debugging section
3. Architecture questions? → Check architectural_decision_records.md
```

**"I need to understand progress"**
```
1. What's done? → Check legacy_implementation_log.md status
2. Documentation outdated? → Use sync_documentation.md one-liner
3. Plan next work? → Use prioritize_work.md master prompt
```

### 📚 Complete Document Catalog

**Core Planning & Strategy:**
- [product_specification.md](../documentation/product_specification.md) - Vision & Requirements (what we're building and why)
- [legacy_implementation_log.md](../documentation/legacy_implementation_log.md) - Progress Tracking (what's done, tested, and working)
- [prioritize_work.md](prioritize_work.md) - Work Prioritization (intelligent task selection system)

**Development Process:**
- [start_feature_development.md](start_feature_development.md) - Feature Development (auto-determine and implement next feature)
- [sync_documentation.md](sync_documentation.md) - Documentation Sync (keep docs aligned with reality)
- [software_development_lifecycle.md](software_development_lifecycle.md) - TDD Workflow (development process and quality standards)
- [development_prompts.md](development_prompts.md) - Prompt Library (templates for common development tasks)

**Technical Reference:**
- [agents.md](agents.md) - Agent Types and Capabilities (roles and responsibilities)
- [architectural_decision_records.md](../documentation/architectural_decision_records.md) - Technical Decisions (architecture choices and reasoning)
- [phoenix_elixir_reference.md](../documentation/phoenix_elixir_reference.md) - Phoenix/Elixir Technical Guidelines

**System Management:**
- [definition_of_done.md](../documentation/definition_of_done.md) - Quality criteria for completion
- [development_log.md](../documentation/development_log.md) - Progress tracking and notes
- [backlog_dashboard.md](../backlog_dashboard.md) - Single source of truth for work prioritization

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
