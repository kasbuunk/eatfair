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

## 🎯 Comprehensive Prompt System Guide

### How to Use the Tag-Based Prompt System

**The EatFair project uses a modular, tag-based prompt system with two types:**

#### Main Task Categories (Complete Workflows)
Use these for end-to-end work processes:
- **#feature_dev** → `prompts/feature_dev.md` - Implement new features using TDD
- **#debug_bug** → `prompts/debug_bug.md` - Systematically investigate and fix bugs  
- **#product_strategy** → `prompts/product_strategy.md` - Plan product direction and prioritization
- **#test_author** → `prompts/test_author.md` - Create comprehensive test coverage
- **#support_triage** → `prompts/support_triage.md` - Process user feedback and issues
- **#code_orient** → `prompts/code_orient.md` - Understand unfamiliar codebase structure
- **#env_setup** → `prompts/env_setup.md` - Set up development environments
- **#quick_fix** → `prompts/quick_fix.md` - Implement small, low-risk changes
- **#refactor** → `prompts/refactor.md` - Improve code quality without changing behavior
- **#incident_resp** → `prompts/incident_resp.md` - Handle production incidents

#### Building Blocks (Composable Steps)
Use these for specific workflow steps:
- **#context_intake** → `prompts/context_intake.md` - Gather requirements and understand work
- **#test_plan** → `prompts/test_plan.md` - Design comprehensive test coverage
- **#write_tests** → `prompts/write_tests.md` - Create tests following TDD principles
- **#impl_change** → `prompts/impl_change.md` - Make code changes with quality safeguards
- **#run_all_tests** → `prompts/run_all_tests.md` - Execute and validate test suite
- **#create_repro** → `prompts/create_repro.md` - Create bug reproduction test cases
- **#isolate_cause** → `prompts/isolate_cause.md` - Systematically find root causes
- **#route_task** → `prompts/route_task.md` - Classify and route incoming work requests
- **#doc_update** → `prompts/doc_update.md` - Update project documentation

### 🔍 Prompt Discovery and Usage

#### When User Includes Tags
1. **Identify Tags**: Look for `#tag` patterns in user requests
2. **Find Prompt Files**: Tags map directly to filenames: `#feature_dev` → `prompts/feature_dev.md`
3. **Read Full Prompt**: Load the complete prompt content and follow its guidance
4. **Apply Configuration**: Reference `prompts_config/` files for EatFair-specific customizations

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
"Use #feature_dev with Phoenix LiveView patterns for real-time notifications"
```
→ Apply main workflow with technology-specific configuration

### ⚙️ Configuration System

#### EatFair-Specific Customizations
All prompts reference configuration files in `prompts_config/`:
- **tech_stack.md** - Phoenix/Elixir patterns and conventions
- **project_context.md** - EatFair business domain and requirements  
- **workflows.md** - Development processes and backlog management
- **quality_standards.md** - Testing approaches and quality gates

#### How Configuration Works
1. **Generic Prompt**: Provides methodology and universal best practices
2. **Configuration Override**: Adds project-specific patterns and requirements
3. **Context Integration**: Applies business domain knowledge and constraints
4. **Workflow Alignment**: Ensures consistency with EatFair development processes

### 🚀 Usage Examples

#### Simple Usage
```
"Use #debug_bug to fix the cart calculation error"
```
→ Applies complete debugging workflow with EatFair configuration

#### Building Block Composition
```
"Apply #context_intake then #isolate_cause to understand this performance issue"
```
→ Explicitly chains specific building blocks

#### Technology Integration
```
"Use #feature_dev with Phoenix LiveView patterns to implement real-time chat"
```
→ Applies development workflow with technology-specific guidance

### 🔗 Prompt Network

**Complete workflow map**: See `prompts/PROMPT_NETWORK.md` for visual dependency mapping

**Cross-references**: Each prompt includes "Related Prompts" section showing:
- **Prerequisites**: What to use before this prompt
- **Complements**: What works alongside this prompt  
- **Follows**: What to use after this prompt

### 📖 Legacy Prompt Migration

**Old System** (Deprecated):
- File-based references like `prioritize_work.md`
- Monolithic prompts with mixed concerns
- Project-specific content mixed with generic guidance

**New System** (Current):
- Tag-based references like `#product_strategy`
- Modular prompts with single responsibilities
- Clean separation of generic methodology and project configuration

**Migration Guide**:
- Replace file references with tag references
- Use building block composition instead of monolithic prompts
- Apply configuration system for project-specific customization

---

**Related Documents**:
- [System Constitution (WARP.md)](WARP.md) - Global principles and operational rules
- [Backlog Dashboard](backlog_dashboard.md) - Current work prioritization
- [Definition of Done](documentation/definition_of_done.md) - Quality criteria for completion
