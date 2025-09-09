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

### 5. Test-First Development Approach
**Principle**: Always prioritize unit testing and static analysis over running live servers for validation.

**Rules**:
- **NEVER** run development servers (`mix phx.server`, `npm start`, etc.) for testing changes
- Use unit tests, integration tests, and static analysis tools instead
- For layout/UI changes: write view tests or component tests
- For route changes: test route configurations programmatically
- For configuration changes: validate with compilation tests
- Only suggest server startup if explicitly requested by user for development purposes

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

---

# Agent System and Tag-Based Prompts

This document defines the roles, responsibilities, and capabilities of different agent modes in our development system, and how they interact with the modular tag-based prompt system.

## Core Agent Modes

### 1. Developer Mode
**Primary Role**: Feature implementation and code development

**Core Capabilities**:
- Writes and modifies application code using project technology stack
- Implements user interfaces, controllers, and business logic
- Creates database migrations and schema definitions
- Follows TDD practices (test-first development)
- Handles authentication flows and route configuration

**Key Responsibilities**:
- Implement features from backlog items according to acceptance criteria
- Write comprehensive tests before implementing functionality
- Ensure code follows established project patterns and best practices
- Update implementation documentation when completing features
- Maintain code quality through proper error handling and validation

**Required Knowledge**:
- Project framework patterns and architecture (see prompts/config/tech_stack.md)
- Language fundamentals and architectural principles
- Database operations and schema management patterns
- UI development patterns and component architectures
- Testing patterns and frameworks

**Project Configuration**: See prompts/config/agent_workflows.md for project-specific specialization areas.

### 2. Reviewer Mode
**Primary Role**: Code review and quality assurance

**Core Capabilities**:
- Analyzes code for adherence to established patterns and conventions
- Identifies potential bugs, security issues, and performance problems
- Validates test coverage and quality
- Ensures documentation is updated appropriately
- Verifies that acceptance criteria are met

**Key Responsibilities**:
- Review all code changes before they are committed
- Validate that completion criteria are met (see project configuration)
- Ensure atomic commits with clear, descriptive messages
- Verify that changes align with architectural decisions
- Check for proper error handling and edge case coverage

**Review Criteria**:
- All tests pass and provide adequate coverage
- Code follows established patterns and conventions
- Documentation is updated to reflect changes
- Security best practices are followed
- Performance implications are considered

### 3. Orchestrator Mode
**Primary Role**: Workflow coordination and task management

**Core Capabilities**:
- Prioritizes work from the backlog based on business value and dependencies
- Coordinates between different agent types
- Manages the development lifecycle and ensures process adherence
- Monitors project progress and identifies blockers
- Facilitates communication between agents

**Key Responsibilities**:
- Maintain the project priority system with current work order
- Assign work to appropriate agent types based on their capabilities
- Ensure the development workflow follows established principles
- Monitor for process improvements and system optimization opportunities
- Coordinate handoffs between development phases

**Decision-Making Authority**:
- Work prioritization and resource allocation
- Process adjustments and workflow improvements
- Escalation of blockers and dependency issues
- Integration of feedback loops and learning

### 4. Documentation Mode
**Primary Role**: Information architecture and knowledge management

**Core Capabilities**:
- Maintains accurate and up-to-date project documentation
- Synthesizes information from multiple sources
- Identifies documentation gaps and inconsistencies
- Creates clear, actionable documentation for different audiences
- Manages the information flow between different system components

**Key Responsibilities**:
- Keep progress tracking current with development status
- Update architectural decision records when significant choices are made
- Ensure consistency between documentation and actual implementation
- Create and maintain prompts for common development tasks
- Archive completed work and maintain historical context

## Agent Interaction Patterns

### Standard Development Flow
1. **Developer** implements feature following way of working
2. **Reviewer** validates implementation against quality criteria
3. **Orchestrator** marks work complete and identifies next priority
4. **Documentation** updates relevant docs and logs progress

### Quality Gates
Each agent mode has specific quality gates that must be satisfied:

- **Developer**: All tests pass, feature meets acceptance criteria
- **Reviewer**: Code quality standards met, security validated
- **Documentation**: All relevant docs updated, progress logged
- **Orchestrator**: Work properly tracked, next priorities identified

## Cross-Cutting Concerns

All agent types must:
- Maintain appropriate version control
- Follow the established information architecture
- Contribute to the continuous improvement feedback loop
- Respect the single source of truth for prioritization

## Specialization Areas

### Technology Development
- Authentication and authorization patterns (see project configuration)
- Framework-specific features and capabilities
- Database design and data operations
- Testing strategies and patterns
- Performance optimization

### Code Quality
- Security best practices
- Error handling and resilience
- Performance monitoring
- Test coverage and quality
- Maintainability and readability

### Process Management
- Backlog prioritization
- Dependency management
- Risk identification
- Progress tracking
- Continuous improvement

---

## 🎯 Comprehensive Prompt System Guide

### How to Use the Tag-Based Prompt System

**The prompt system is organized into a modular, tag-based architecture:**

#### Main Task Categories (Complete Workflows)
Use these for end-to-end work processes:
- **#feature_dev** → `prompts/tasks/feature_dev.md` - Implement new features using TDD
- **#debug_bug** → `prompts/tasks/debug_bug.md` - Systematically investigate and fix bugs  
- **#product_strategy** → `prompts/tasks/product_strategy.md` - Plan product direction and prioritization
- **#test_author** → `prompts/tasks/test_author.md` - Create comprehensive test coverage
- **#support_triage** → `prompts/tasks/support_triage.md` - Process user feedback and issues
- **#code_orient** → `prompts/tasks/code_orient.md` - Understand unfamiliar codebase structure
- **#env_setup** → `prompts/tasks/env_setup.md` - Set up development environments
- **#quick_fix** → `prompts/tasks/quick_fix.md` - Implement small, low-risk changes
- **#refactor** → `prompts/tasks/refactor.md` - Improve code quality without changing behavior
- **#incident_resp** → `prompts/tasks/incident_resp.md` - Handle production incidents

#### Building Blocks (Composable Steps)
Use these for specific workflow steps:
- **#context_intake** → `prompts/tasks/context_intake.md` - Gather requirements and understand work
- **#test_plan** → `prompts/tasks/test_plan.md` - Design comprehensive test coverage
- **#write_tests** → `prompts/tasks/write_tests.md` - Create tests following TDD principles
- **#impl_change** → `prompts/tasks/impl_change.md` - Make code changes with quality safeguards
- **#run_all_tests** → `prompts/tasks/run_all_tests.md` - Execute and validate test suite
- **#create_repro** → `prompts/tasks/create_repro.md` - Create bug reproduction test cases
- **#isolate_cause** → `prompts/tasks/isolate_cause.md` - Systematically find root causes
- **#route_task** → `prompts/tasks/route_task.md` - Classify and route incoming work requests
- **#doc_update** → `prompts/tasks/doc_update.md` - Update project documentation

### 🔍 Prompt Discovery and Usage

#### When User Includes Tags
1. **Identify Tags**: Look for `#tag` patterns in user requests
2. **Find Prompt Files**: Tags map directly to filenames: `#feature_dev` → `prompts/tasks/feature_dev.md`
3. **Read Full Prompt**: Load the complete prompt content and follow its guidance
4. **Apply Configuration**: Reference `prompts/config/` files for project-specific customizations
3. **Recursively unfold**: Where more context is relevant, recursively read any prompt referenced by tag

#### When No Tags Present
1. **Apply Classification**: Use `#route_task` to classify the type of work
2. **Suggest Appropriate Tags**: Recommend relevant prompts based on work type
3. **Compose Workflow**: Chain multiple prompts if complex work is needed

#### Fallback Strategy When Prompt Not Found
1. **Check Similar Categories**: Look for related prompts that might cover the work
2. **Compose from Building Blocks**: Combine building block prompts to create workflow
3. **Use Generic Patterns**: Apply closest existing prompt with modifications
4. **Request Clarification**: Ask user to refine request or provide more specific category

### 📋 Tag Composition Patterns

#### Sequential Composition (Pipeline)
```
"Apply #context_intake then #test_plan then #write_tests for user authentication"
```
→ Chain building blocks in sequence for complex workflows

#### Conditional Composition (Routing)
```
"Use #route_task to determine if this needs #feature_dev or #debug_bug"
```
→ Use routing to select appropriate main workflow

#### Configuration Integration
```
"Use #feature_dev with technology-specific patterns for real-time features"
```
→ Apply main workflow with technology-specific configuration

### ⚙️ Configuration System

The prompt system uses a **layered approach**: generic methodologies (`prompts/tasks/`) + project-specific configuration (`prompts/config/`) = contextualized guidance.

**Key Configuration Files**: `tech_stack.md`, `project_context.md`, `workflows.md`, `quality_standards.md`

📖 **See More**: Complete configuration documentation in [`prompts/README.md`](prompts/README.md#-configuration-override-system)

### 🚀 Usage Examples

#### Simple Usage
```
"Use #debug_bug to fix the calculation error"
```
→ Applies complete debugging workflow with project configuration

#### Building Block Composition
```
"Apply #context_intake then #isolate_cause to understand this performance issue"
```
→ Explicitly chains specific building blocks

#### Technology Integration
```
"Use #feature_dev with project-specific patterns to implement real-time features"
```
→ Applies development workflow with technology-specific guidance

### 🔗 Prompt Network

**Complete workflow map**: See `prompts/tasks/prompt_network.md` for visual dependency mapping

**Cross-references**: Each prompt includes "Related Prompts" section showing:
- **Prerequisites**: What to use before this prompt
- **Complements**: What works alongside this prompt  
- **Follows**: What to use after this prompt

---

**Related Documents**:
- [Definition of Done](documentation/definition_of_done.md) - Quality criteria for completion
