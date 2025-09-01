# System Constitution (WARP)

This document defines the global principles and operational rules that govern our entire development system. These principles are universal and must be followed by all agents, regardless of their specialized role.

**Project-Specific Configuration**: For project-specific implementations of these principles (technology stacks, tools, commands), see the `prompts_config/` directory.

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

## 🎯 Agent Navigation Guide

*For comprehensive prompt navigation and agent coordination, see [AGENTS.md](AGENTS.md) which contains the complete tag-based prompt directory and agent interaction patterns.*

### Tag-Based Prompt System

**The prompt system is organized into a modular, tag-based architecture:**

#### Main Task Categories
Complete workflows for major types of work:
- **Feature Development** → Use `#feature_dev` for new functionality implementation
- **Bug Debugging** → Use `#debug_bug` for systematic issue resolution
- **Product Strategy** → Use `#product_strategy` for planning and prioritization
- **Test Authoring** → Use `#test_author` for comprehensive test coverage
- **Support Triage** → Use `#support_triage` for feedback and issue processing

#### Building Blocks
Composable workflow steps that can be chained:
- **Context Intake** → Use `#context_intake` to gather requirements
- **Test Planning** → Use `#test_plan` to design test coverage
- **Writing Tests** → Use `#write_tests` following TDD principles
- **Implementation** → Use `#impl_change` with quality safeguards
- **Running Tests** → Use `#run_all_tests` to validate functionality
- **Bug Reproduction** → Use `#create_repro` for minimal test cases
- **Root Cause Analysis** → Use `#isolate_cause` for systematic investigation

**Usage Pattern**: Include hashtags in requests to access specific guidance:
- `"Use #feature_dev to implement [specific functionality]"`
- `"Use #debug_bug to fix [specific issue]"`
- `"Apply #context_intake then #isolate_cause to understand [problem]"`

## Development Workflow

### TDD Development Checklist

**CRITICAL**: Always follow this checklist for any development work:

#### 🚀 **Start Phase**
- [ ] Check project priority system for current priority
- [ ] Create todo list for work (if 3+ steps required)
- [ ] **Add final todo**: "Update backlog item status with progress"

#### 🔄 **During Development**
- [ ] Write failing tests first
- [ ] Implement minimum code to make tests pass
- [ ] Update backlog item status when significant progress made
- [ ] Refactor while keeping tests green

#### ✅ **Completion Phase** 
- [ ] All tests pass
- [ ] **Update backlog item status**:
  - [ ] Mark item as #status/done if complete
  - [ ] Update priority system if priorities changed
  - [ ] Document any architectural decisions in ADRs
- [ ] Mark todos as complete

### Project Quick Start

**New to the project?** Start here:
```
# Check project setup instructions
# Navigation guide is built into this WARP.md file (see Agent Navigation Guide above)
```

**Daily development session:**
```
# Check current priorities
"Use #product_strategy to determine what work to prioritize next"
# Then implement using TDD
"Use #feature_dev to implement the next priority feature"
```

**Need specific guidance?**
- 🎯 **What to work on**: Use `#product_strategy` for work prioritization
- 📋 **Feature development**: Use `#feature_dev` for TDD implementation
- 🔧 **Fix issues**: Use `#support_triage` or `#debug_bug` for systematic issue resolution
- 🧪 **Test problems**: Use `#test_author` for comprehensive testing

## Development Principles

- **TDD is non-negotiable** - write tests first for every feature
- **Backlog management is non-negotiable** - priority system and individual backlog items must be kept current
- Use project-specific validation commands before committing changes
- Follow established technology patterns (see project configuration)
- Use the Agent Navigation Guide (above) when you need to find specific project information

## Backlog Management Workflow

**The project priority system is the single source of truth** for work prioritization and must be updated:

### When to Update Backlog Items
- **During development**: Update status tags as work progresses
- **At completion**: Mark items as #status/done when meeting Definition of Done
- **When blocked**: Update status to #status/blocked with blocker details
- **When pivoting**: Update priority system order

### Status Management
- **Status Tags**: Use #status/todo, #status/in_progress, #status/blocked, #status/done
- **Priority Order**: Update priority system when priorities change
- **New Items**: Add detailed specifications in backlog directory
- **Technical Notes**: Document architectural decisions in ADRs

### Update Pattern
```
1. Complete development work
2. Ensure all tests pass
3. Update backlog item status and priority order if needed
4. Commit both code and backlog updates together
```
