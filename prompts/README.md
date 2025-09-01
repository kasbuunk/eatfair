# EatFair Prompts Directory

**Unified prompt system containing both generic methodologies and project-specific configurations.**

## 🎯 Quick Navigation

### **Core Foundation**
- **`product_specification.md`** ← **THE MOST IMPORTANT DOCUMENT** - Complete product vision, features, and decision-making guidance

### **For AI Agents**
- **`tasks/`** - Generic prompt methodologies (reusable across projects)
- **`config/`** - EatFair-specific configurations and context

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
├── config/                   # EatFair-specific configurations
│   ├── project_context.md    # Business domain and current status
│   ├── tech_stack.md         # Phoenix/Elixir patterns and conventions
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

- **Product vision and mission** - What EatFair exists to accomplish
- **Target audience and user journeys** - Who we're building for and how they use the platform  
- **Feature priorities and requirements** - What to build and why
- **Design philosophy and values** - How to make decisions about UX, features, and behavior
- **Business constraints and opportunities** - What drives our technical and product choices

**Any prompt that needs to make choices about features, taste, or application behavior should reference the product specification first.**

## 📝 Using Task Prompts

Task prompts in `tasks/` are **generic methodologies** that work across projects. To use them with EatFair context:

```
Use #feature_dev with EatFair product specification for implementing restaurant discovery
Use #debug_bug with EatFair tech stack patterns for Phoenix LiveView issues
Use #test_author with EatFair quality standards for comprehensive test coverage
```

## ⚙️ Project Configuration

Files in `config/` provide **EatFair-specific context** that customizes the generic task prompts:

- **`project_context.md`** - Current project status, user journeys, success metrics
- **`tech_stack.md`** - Phoenix/Elixir patterns, database schemas, testing approaches
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
3. **Reference config files** - Apply EatFair-specific patterns and standards
4. **Update progress** - Keep backlog and implementation status current

### For Bug Debugging  
1. **Use `#debug_bug` task prompt** - Follow systematic debugging methodology
2. **Reference `config/security.md`** - Check for security implications
3. **Reference `config/tech_stack.md`** - Apply Phoenix/Elixir debugging patterns
4. **Document learnings** - Update relevant configuration or archive docs

### For Testing and Quality
1. **Use `#test_author` task prompt** - Follow comprehensive testing methodology
2. **Reference `config/quality_standards.md`** - Apply DoD checklist and audit rules
3. **Reference `config/tech_stack.md`** - Use Phoenix LiveView testing patterns
4. **Validate completeness** - Ensure all quality gates are met

## 🔄 Single Source of Truth

This unified structure maintains WARP.md principles:

- **Product Specification** - Single source for product vision and feature guidance
- **Task Prompts** - Reusable methodologies without duplication
- **Configuration** - Project-specific context that customizes generic prompts
- **Archives** - Historical preservation without active development pollution

## 🚀 Getting Started

**For any development task:**

1. Read `product_specification.md` for product vision and feature context
2. Choose appropriate task prompt from `tasks/` directory
3. Apply relevant configurations from `config/` directory  
4. Reference `archive/` for historical context if needed

This structure provides both the flexibility of generic prompts and the specificity of project context while keeping the product specification at the center of all decision-making.
