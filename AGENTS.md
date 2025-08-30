# Agent Types and Capabilities

This document defines the roles, responsibilities, and capabilities of different agent types in our development system. Each agent type has specialized knowledge and specific responsibilities within our workflow.

## Core Agent Types

### 1. Developer Agent
**Primary Role**: Feature implementation and code development

**Core Capabilities**:
- Writes and modifies Phoenix/Elixir application code
- Implements LiveViews, controllers, and business logic
- Creates database migrations and schema definitions
- Follows TDD practices (test-first development)
- Handles authentication flows and route configuration

**Key Responsibilities**:
- Implement features from backlog items according to acceptance criteria
- Write comprehensive tests before implementing functionality
- Ensure code follows Phoenix v1.8 and Elixir best practices
- Update implementation documentation when completing features
- Maintain code quality through proper error handling and validation

**Required Knowledge**:
- Phoenix framework patterns and LiveView architecture
- Elixir language fundamentals and OTP principles
- Ecto for database operations and schema management
- HEEx templating and component-based UI development
- Testing patterns with Phoenix.LiveViewTest

**Links to Technical Guidelines**: See [Phoenix/Elixir Technical Reference](documentation/phoenix_elixir_reference.md)

### 2. Reviewer Agent
**Primary Role**: Code review and quality assurance

**Core Capabilities**:
- Analyzes code for adherence to established patterns and conventions
- Identifies potential bugs, security issues, and performance problems
- Validates test coverage and quality
- Ensures documentation is updated appropriately
- Verifies that acceptance criteria are met

**Key Responsibilities**:
- Review all code changes before they are committed
- Validate that the [Definition of Done](documentation/definition_of_done.md) criteria are met
- Ensure atomic commits with clear, descriptive messages
- Verify that changes align with architectural decisions
- Check for proper error handling and edge case coverage

**Review Criteria**:
- All tests pass and provide adequate coverage
- Code follows established patterns and conventions
- Documentation is updated to reflect changes
- Security best practices are followed
- Performance implications are considered

### 3. Orchestrator Agent
**Primary Role**: Workflow coordination and task management

**Core Capabilities**:
- Prioritizes work from the backlog based on business value and dependencies
- Coordinates between different agent types
- Manages the development lifecycle and ensures process adherence
- Monitors project progress and identifies blockers
- Facilitates communication between agents

**Key Responsibilities**:
- Maintain the [Backlog Dashboard](backlog_dashboard.md) with current priorities
- Assign work to appropriate agent types based on their capabilities
- Ensure the development workflow follows established principles
- Monitor for process improvements and system optimization opportunities
- Coordinate handoffs between development phases

**Decision-Making Authority**:
- Work prioritization and resource allocation
- Process adjustments and workflow improvements
- Escalation of blockers and dependency issues
- Integration of feedback loops and learning

### 4. Documentation Agent
**Primary Role**: Information architecture and knowledge management

**Core Capabilities**:
- Maintains accurate and up-to-date project documentation
- Synthesizes information from multiple sources
- Identifies documentation gaps and inconsistencies
- Creates clear, actionable documentation for different audiences
- Manages the information flow between different system components

**Key Responsibilities**:
- Keep [Development Log](documentation/development_log.md) current with progress
- Update architectural decision records when significant choices are made
- Ensure consistency between documentation and actual implementation
- Create and maintain prompts for common development tasks
- Archive completed work and maintain historical context

## Agent Interaction Patterns

### Standard Development Flow
1. **Orchestrator** identifies next priority from backlog
2. **Developer** implements feature following TDD practices
3. **Reviewer** validates implementation against quality criteria
4. **Documentation** updates relevant docs and logs progress
5. **Orchestrator** marks work complete and identifies next priority

### Quality Gates
Each agent type has specific quality gates that must be satisfied:

- **Developer**: All tests pass, feature meets acceptance criteria
- **Reviewer**: Code quality standards met, security validated
- **Documentation**: All relevant docs updated, progress logged
- **Orchestrator**: Work properly tracked, next priorities identified

## Cross-Cutting Concerns

All agent types must:
- Adhere to the global principles defined in [System Constitution](WARP.md)
- Maintain atomic commits with descriptive messages
- Follow the established information architecture
- Contribute to the continuous improvement feedback loop
- Respect the single source of truth for prioritization (Backlog Dashboard)

## Specialization Areas

### Phoenix/Elixir Development
- Authentication and authorization patterns
- LiveView and real-time features
- Database design and Ecto operations
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

## Prompt Tag Directory

*When users include #tags in their requests, reference the appropriate prompts to provide comprehensive guidance.*

### Universal Principles (Project-Agnostic)
- **#tdd** → `prompts/tdd_principles.md` - Core test-driven development cycle and practices
- **#quality** → `prompts/quality_gates.md` - Universal quality standards and automated checks
- **#git** → `prompts/git.md` - Version control workflow and best practices

### Technology-Specific Guidelines
- **#elixir** → `prompts/elixir.md` - Elixir language patterns and conventions
- **#phoenix** → `prompts/phoenix.md` - Phoenix framework patterns and LiveView guidelines
- **#llms** → `prompts/llms.md` - LLM interaction patterns and prompt engineering

### Project Development Methodology
- **#mvp** → `prompts/mvp_development.md` - MVP development methodology and early-stage practices
- **#greenfield** → `prompts/greenfield_project.md` - New project development without legacy constraints

### Workflow and Process
- **#prioritization** → `prompts/prioritize_work.md` - Work prioritization system and decision framework
- **#feedback** → `prompts/process_feedback.md` - Systematic feedback processing and issue resolution
- **#documentation** → `prompts/sync_documentation.md` - Documentation sync and maintenance
- **#testing** → `prompts/validate_and_fix_tests.md` - Test validation and debugging
- **#development** → `prompts/start_feature_development.md` - Feature development workflow

### Comprehensive Development
- **#prompts** → `prompts/development_prompts.md` - Collection of common development task prompts
- **#lifecycle** → `prompts/software_development_lifecycle.md` - EatFair-specific development workflow

### Tag Usage Guidelines

**Single Tag Usage**: Use one primary tag to focus on specific guidance
```
"I need help with #tdd for implementing user authentication"
```

**Multiple Tag Usage**: Combine tags for comprehensive guidance
```
"I need to implement a new feature using #tdd #phoenix #mvp principles"
```

**Tag Resolution Process**:
1. **Identify Primary Domain**: Determine the main area of focus
2. **Reference Appropriate Prompts**: Read the tagged prompt files for guidance
3. **Apply Context**: Adapt general principles to specific project context
4. **Integrate Guidelines**: Combine multiple tagged guidelines when relevant

---

**Related Documents**:
- [System Constitution (WARP.md)](WARP.md) - Global principles and operational rules
- [Backlog Dashboard](backlog_dashboard.md) - Current work prioritization
- [Definition of Done](documentation/definition_of_done.md) - Quality criteria for completion
