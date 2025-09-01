# Prompts Directory

**Unified prompt system containing both generic methodologies and project-specific configurations.**

## 🎯 Quick Navigation

### **Core Foundation**
- **`product_specification.md`** ← **THE MOST IMPORTANT DOCUMENT** - Complete product vision, features, and decision-making guidance

### **For AI Agents**
- **`tasks/`** - Generic prompt methodologies (reusable across projects)
- **`config/`** - Product-specific configurations and context

### **For Historical Reference**  
- **`archive/`** - Complete project history and archived documentation

## 📋 Directory Structure

```
prompts/
├── product_specification.md    # 🌟 FOUNDATIONAL DOCUMENT - Product vision & guidance
├── tasks/                     # Generic prompt methodologies
│   ├── feature_dev.md         # Feature development workflow
│   ├── debug_bug.md          # Bug debugging methodology
│   ├── test_author.md        # Test writing and validation
│   ├── context_intake.md     # Requirements gathering
│   ├── product_strategy.md   # Strategic planning
│   └── [20+ other task prompts...]
├── config/                   # Product-specific configurations
│   ├── project_context.md    # Business domain and current status
│   ├── tech_stack.md         # Product-specific patterns and conventions
│   ├── quality_standards.md  # Testing and quality requirements
│   ├── workflows.md          # Development processes
│   ├── security.md          # Security patterns and procedures
│   ├── architecture.md      # Architectural guidance and ADR templates
│   └── backlog_management.md # Work prioritization and tracking
└── archive/                 # Historical documentation
    ├── adr/                 # Architectural Decision Records
    ├── security_incidents/  # Security incident reports  
    ├── legacy_implementation_log.md
    ├── development_log.md
    ├── features_completed.md
    └── [other historical docs...]
```

## 🌟 Using the Product Specification

**`product_specification.md` is the foundational document** that should inform ALL development decisions. Reference it whenever you need guidance on:

- **Product vision and mission** - What the product exists to accomplish
- **Target audience and user journeys** - Who we're building for and how they use the platform  
- **Feature priorities and requirements** - What to build and why
- **Design philosophy and values** - How to make decisions about UX, features, and behavior
- **Business constraints and opportunities** - What drives our technical and product choices

**Any prompt that needs to make choices about features, taste, or application behavior should reference the product specification first.**

## 📝 Using Task Prompts

Task prompts in `tasks/` are **generic methodologies** that work across projects. To use them with the product's context:

```
Use #feature_dev with the product specification for implementing a new feature
Use #debug_bug with the tech stack patterns for troubleshooting issues
Use #test_author with our quality standards for comprehensive test coverage
```

## ⚙️ Project Configuration

Files in `config/` provide **Product-specific context** that customizes the generic task prompts:

- **`project_context.md`** - Current project status, user journeys, success metrics
- **`tech_stack.md`** - Tech stack, patterns, database schemas, design philosophy
- **`quality_standards.md`** - Definition of done, security checklists, test audit rules
- **`workflows.md`** - Development processes and contributor interaction guidelines
- **`security.md`** - Security patterns, incident response, vulnerability management
- **`architecture.md`** - Architectural decision framework and common patterns
- **`backlog_management.md`** - Work prioritization and progress tracking

## 📚 Historical Reference

The `archive/` directory preserves complete project history:

- **Development decisions and evolution** - How we got to where we are
- **Completed feature documentation** - Historical implementation details
- **Security incidents and learnings** - How we've handled security challenges
- **Architectural decision records** - Why we made specific technical choices

## 🎯 Agent Navigation Guide

### For Feature Development
1. **Start with product specification** - Understand the vision and requirements
2. **Use `#feature_dev` task prompt** - Follow systematic development methodology  
3. **Reference config files** - Apply product-specific patterns and standards
4. **Update progress** - Keep backlog and implementation status current

### For Debugging  
1. **Use `#debug_bug` task prompt** - Follow systematic debugging methodology
2. **Reference `config/security.md`** - Check for security implications
3. **Reference `config/tech_stack.md`** - Apply Tech specific debugging patterns
4. **Document learnings** - Update relevant configuration or archive docs

### For Testing and Quality
1. **Use `#test_author` task prompt** - Follow comprehensive testing methodology
2. **Reference `config/quality_standards.md`** - Apply DoD checklist and audit rules
3. **Reference `config/tech_stack.md`** - Use our chosen testing patterns
4. **Validate completeness** - Ensure all quality gates are met

## 🔄 Single Source of Truth

This unified structure maintains principles:

- **Product Specification** - Single source for product vision and feature guidance
- **Task Prompts** - Reusable methodologies without duplication
- **Configuration** - Project-specific context that customizes generic prompts  
- **Archives** - Historical preservation without active development pollution

## 🔄 **Configuration Override System**

The prompt system operates on a **layered approach** for maximum reusability:

### Core Principle
1. **Generic Foundation** (`prompts/tasks/`) - Universal best practices and methodologies
2. **Project Configuration** (`prompts/config/`) - Specific overrides, patterns, and context
3. **Product Context** (`prompts/product_specification.md`) - Business domain and feature guidance

### How Overrides Work
When an agent processes a tagged prompt request:

1. **Load Generic Prompt** - Read the base methodology from `prompts/tasks/[prompt_name].md`
2. **Apply Configuration** - Layer in project-specific context from `prompts/config/` files  
3. **Context Integration** - Combine both to create the final, contextualized guidance

### Configuration Integration Points
Each generic prompt includes **Configuration References** that specify which config files to consider:

```markdown
Apply technology-specific patterns from: prompts/config/tech_stack.md  
Follow project quality standards from: prompts/config/quality_standards.md  
Integrate with project workflows from: prompts/config/workflows.md
```

### Configuration File Types

**Cross-Cutting Configuration Files** (apply across multiple prompt types):
- **`tech_stack.md`** - Technology patterns, frameworks, libraries, coding conventions
- **`project_context.md`** - Business domain, user journeys, product requirements  
- **`quality_standards.md`** - Testing standards, Definition of Done, audit checklists
- **`workflows.md`** - Development processes, git workflows, backlog management
- **`security.md`** - Security patterns, vulnerability procedures, compliance requirements

**Prompt-Specific Overrides** (specialized configuration):
- **`prompts/config/feature_dev.md`** - Project-specific feature development patterns
- **`prompts/config/debug_bug.md`** - Technology-specific debugging approaches
- **`prompts/config/test_author.md`** - Project testing frameworks and patterns

## 🚀 **Team Bootstrap Instructions**

### For New Projects Using This System

#### Step 1: Copy Generic Foundation
```bash
# Copy the generic prompts from company repository
cp -r /path/to/company-prompts/tasks ./prompts/
cp /path/to/company-prompts/AGENTS.md ./
cp /path/to/company-prompts/scripts/validate_prompts.sh ./scripts/
```

#### Step 2: Create Project Configuration
```bash
# Create your project-specific configuration directory
mkdir -p prompts/config

# Create core configuration files (customize these templates)
touch prompts/config/tech_stack.md
touch prompts/config/project_context.md  
touch prompts/config/quality_standards.md
touch prompts/config/workflows.md
touch prompts/config/security.md
```

#### Step 3: Customize Configuration Files
Each configuration file should follow this structure:

```markdown
# [Configuration Area] Configuration

**Project**: [Your Project Name]  
**Last Updated**: [Date]

## Overview
Brief description of what this configuration covers.

## [Project Name] Specifics
Project-specific implementations, patterns, and requirements.

### Technology Stack
- Framework: [specific framework + version]
- Libraries: [specific choices and versions]
- Patterns: [architectural patterns used]

### Quality Standards  
- Testing: [specific testing approaches]
- Performance: [specific thresholds]
- Security: [specific requirements]

## Examples
Concrete examples of how to apply these configurations.

## Related Generic Prompts
List which `prompts/tasks/` files reference this configuration.
```

#### Step 4: Create Product Specification
```bash
# Create your product specification (the most important document)
touch prompts/product_specification.md
```

#### Step 5: Validate Your Setup
```bash
# Run validation to ensure everything is properly configured
./scripts/validate_prompts.sh
```

### Usage Examples

#### Basic Usage
```
Use #feature_dev to implement user authentication
```
→ Loads `prompts/tasks/feature_dev.md` + applies all referenced config files

#### Explicit Configuration Reference  
```
Use #debug_bug with technology-specific patterns for database issues
```
→ Emphasizes applying `prompts/config/tech_stack.md` for database debugging

#### Multi-Configuration Integration
```
Use #test_author with project testing standards and security requirements
```
→ Applies both `prompts/config/quality_standards.md` and `prompts/config/security.md`

### Implementation Guidelines

**For Generic Prompts** (`prompts/tasks/`):
✅ **DO include**: Universal methodologies, technology-agnostic workflows, generic quality gates
❌ **NEVER include**: Specific technology stacks, product-specific business logic, particular tool names

**For Configuration Files** (`prompts/config/`):
✅ **DO include**: Technology-specific patterns, project business context, specific tools and frameworks
❌ **AVOID duplicating**: Generic methodologies (keep those in `prompts/tasks/`)

## 🚀 Getting Started

**For any development task:**

1. **Read `product_specification.md`** for product vision and feature context
2. **Choose appropriate task prompt** from `tasks/` directory
3. **Apply relevant configurations** from `config/` directory  
4. **Reference `archive/`** for historical context if needed
5. **Run validation** with `./scripts/validate_prompts.sh` to ensure system integrity

This layered system provides the flexibility of customization with the consistency of shared best practices.
