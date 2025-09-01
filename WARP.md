# System Constitution (WARP)

This document defines the global principles and operational rules that govern our entire development system. These principles are universal and must be followed by all agents, regardless of their specialized role.

**Project-Specific Configuration**: For project-specific implementations of these principles (technology stacks, tools, commands), see the `prompts/config/` directory.

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
- Work prioritization has one authoritative source (see project workflows)
- Progress tracking has one authoritative location  
- Completion criteria are defined in one place
- Avoid duplicating information across multiple documents

### 4. Continuous Integration
**Principle**: Changes are integrated frequently and validated automatically.

**Rules**:
- Use project-specific validation commands before every commit
- All quality gates must pass before merging
- Broken builds must be fixed immediately
- Changes should be small, frequent, and incremental

## Operational Rules

### Information Architecture
**Directory Structure Principles**:
- Separate documentation from implementation code
- Agent prompts and workflow definitions have dedicated location
- Individual work items have detailed specifications
- Work prioritization has a single source of truth

**Naming Conventions**:
- All directories and files use consistent naming patterns
- File names should be descriptive and indicate their purpose
- Avoid abbreviations unless they are widely understood

### Status Management
**Status Tags**: All work items must have one status tag:
- `#status/todo` - Not yet started
- `#status/in_progress` - Currently being worked on
- `#status/blocked` - Waiting on external dependencies
- `#status/done` - Meets all completion criteria

**Priority Order**: Work prioritization follows a single source of truth principle.

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
- Follow established patterns and conventions (see project configuration)
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

## 🎯 Quick Reference

**For comprehensive prompt navigation and agent coordination, see [AGENTS.md](AGENTS.md) and [`prompts/README.md`](prompts/README.md).**

### Essential Commands
- **Work Prioritization**: `Use #product_strategy to determine what work to prioritize next`
- **Feature Development**: `Use #feature_dev to implement [feature] following TDD principles`
- **Bug Resolution**: `Use #debug_bug to fix [specific issue]`
- **Test Coverage**: `Use #test_author for comprehensive testing`

### Development Checklist (TDD)
1. **Red**: Write failing test → **Green**: Make it pass → **Refactor**: Improve code
2. Update backlog status throughout development
3. Commit code + backlog updates together
4. Validate with project-specific quality gates

### Non-Negotiable Principles
- **TDD is mandatory** - tests before implementation, always
- **Backlog management is mandatory** - status must reflect reality
- **Single source of truth** - avoid information duplication
- **Atomic commits** - each commit is complete and self-contained
