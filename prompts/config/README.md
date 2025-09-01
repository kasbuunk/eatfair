# EatFair Prompt Configuration

## Purpose

This directory contains **project-specific configurations** that customize the reusable prompts in `prompts/` for the EatFair project. These configurations include:

- **Technology stack preferences** - Phoenix, Elixir, LiveView patterns
- **Workflow customizations** - EatFair-specific development processes
- **Business context** - Domain knowledge and project requirements
- **Quality standards** - Project-specific quality gates and testing approaches

## File Structure

Configuration files correspond to prompts in `prompts/`:
- `tech_stack.md` - Technology patterns (Phoenix, Elixir, Git)
- `project_context.md` - EatFair business domain and requirements
- `quality_standards.md` - Testing and quality approaches
- `workflows.md` - Development processes and documentation practices

## How Configuration Works

When you use `#feature_dev`, the prompt will:
1. Load the generic methodology from `prompts/feature_dev.md`  
2. Apply project-specific customizations from `prompts_config/feature_dev.md`
3. Reference technology patterns from `prompts_config/tech_stack.md`
4. Include business context from `prompts_config/project_context.md`

## Configuration Files

### Core Configuration
- `project_context.md` - What EatFair is, business requirements, user journeys
- `tech_stack.md` - Phoenix, Elixir, LiveView, testing patterns
- `quality_standards.md` - TDD approach, quality gates, documentation standards
- `workflows.md` - Development processes, git workflow, backlog management

### Specific Customizations
- `feature_dev.md` - EatFair-specific feature development process
- `debug_bug.md` - EatFair debugging workflows and tools
- `test_author.md` - EatFair testing patterns and standards

## Usage

Configuration is automatically applied when using prompts. You can also explicitly reference config:

```
Use #feature_dev with EatFair business context for the restaurant discovery feature
```

## Editing Guidelines

1. **Keep reusable content in `prompts/`** - Only put EatFair-specific content here
2. **Reference generic prompts** - Don't duplicate methodology, just customize it  
3. **Include concrete examples** - Use actual EatFair features and requirements
4. **Update regularly** - Keep configuration current with project evolution

---

**Related Documents**:
- [System Constitution (WARP.md)](WARP.md) - Global principles and operational rules
- [Backlog Dashboard](backlog_dashboard.md) - Current work prioritization
