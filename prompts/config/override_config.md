# Configuration Override Mechanism

This document explains how the layered configuration system works to allow customization of generic prompts.

## Override Hierarchy

The prompt system operates on a **layered approach** for maximum reusability:

1. **Generic Foundation** (`prompts/tasks/`) - Universal best practices and methodologies
2. **Project Configuration** (`prompts/config/`) - Technology stack and project-specific overrides  
3. **Product Context** (`prompts/product_specification.md`) - Business domain and feature guidance

## Configuration Files

### Technology Stack (`tech_stack.md`)
Defines project-specific tools, frameworks, and technical approaches:
- Programming languages and frameworks
- Testing frameworks and tools
- Deployment and infrastructure tools
- Development environment setup

### Workflows (`workflows.md`)  
Customizes generic methodologies for project needs:
- Development process variations
- Quality gates and approval processes
- Integration and deployment procedures
- Team coordination protocols

### Quality Standards (`quality_standards.md`)
Project-specific quality criteria:
- Code quality standards and conventions
- Testing requirements and coverage thresholds
- Performance and security requirements
- Documentation standards

### Agent Workflows (`agent_workflows.md`)
Customizes agent coordination for project context:
- Agent roles and responsibilities
- Work routing and assignment rules
- Communication protocols
- Escalation procedures

## How Overrides Work

### Generic Prompt Structure
Each generic prompt includes configuration points:
```markdown
Use project tools from: prompts/config/tech_stack.md
Follow project workflows from: prompts/config/workflows.md
Apply quality standards from: prompts/config/quality_standards.md
```

### Configuration Integration
When a generic prompt is used:
1. The generic methodology provides the framework
2. Configuration files supply project-specific details
3. Product specification provides business context
4. All layers combine to create complete guidance

### Example Override
**Generic**: "Apply appropriate testing framework"
**Config Override**: "Use Jest for unit tests, Cypress for E2E tests"
**Result**: Specific, actionable guidance for the project

## Configuration Templates

### New Project Setup
1. Copy configuration templates from existing project
2. Customize for new technology stack and requirements
3. Update product specification for business domain
4. Validate configuration with prompt validation script

### Configuration Maintenance
- Review and update configurations during retrospectives
- Keep configurations in sync with project changes
- Document configuration decisions and rationale
- Share successful configuration patterns across teams

## Benefits

### For Development Teams
- **Consistency**: Same methodologies across team members
- **Flexibility**: Adapt to project-specific needs and constraints
- **Efficiency**: No need to rewrite generic best practices

### For Organizations
- **Standardization**: Common quality and process standards
- **Reusability**: Share configurations across similar projects
- **Governance**: Central oversight with local customization

## Validation

Use `scripts/validate_prompts.sh` to ensure:
- All configuration references resolve correctly
- No broken links between prompts and configurations
- Configuration files contain required sections
