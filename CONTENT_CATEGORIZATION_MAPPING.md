# Content Categorization Mapping

This document maps existing content to new categorical structure for prompt redistribution.

## Categories

1. **Universal Principles** - Tech and product agnostic development principles
2. **Technology-Specific** - Elixir, Phoenix, SQLite, Git, LLMs
3. **Project Build Characteristics** - How to build (MVP vs enterprise, greenfield vs legacy)
4. **Product Domain** - What to build (EatFair-specific business logic)

## Content Distribution Plan

### Universal Principles (New Files)

**`prompts/tdd_principles.md` #tdd**
- From `software_development_lifecycle.md` lines 1-56: Core TDD philosophy, Red-Green-Refactor cycle
- From `software_development_lifecycle.md` lines 22-41: Testing hierarchy (E2E, Integration, Unit) - make tech-agnostic
- From `software_development_lifecycle.md` lines 42-57: Quality standards (readability, speed, coverage)

**`prompts/quality_gates.md` #quality**  
- From `software_development_lifecycle.md` lines 115-133: CI checks (generalized from mix commands)
- From `development_prompts.md` lines 512-534: Pre-commit quality checks (generalized)
- From `validate_and_fix_tests.md` lines 144-158: Quality assurance checklist (generalized)

**`prompts/work_prioritization_principles.md` #prioritization**
- From `prioritize_work.md` lines 398-450: Decision framework, early-stage principles, anti-patterns
- Universal prioritization logic without EatFair references

**`prompts/feedback_processing_principles.md` #feedback**
- From `process_feedback.md` lines 25-88: Universal feedback categorization and analysis framework
- Remove EatFair-specific examples

**`prompts/documentation_discipline.md` #documentation**
- From `sync_documentation.md`: Universal documentation sync principles
- From `development_prompts.md` lines 310-403: Documentation patterns (generalized)

### Technology-Specific (New Files)

**`prompts/elixir.md` #elixir**
- From `phoenix_elixir_reference.md` lines 79-115: Pure Elixir guidelines
- From `software_development_lifecycle.md` lines 116-121: Mix guidelines

**`prompts/phoenix.md` #phoenix**
- From `phoenix_elixir_reference.md` lines 10-78: Phoenix v1.8, Authentication, routing
- From `phoenix_elixir_reference.md` lines 122-200: Phoenix HTML, HEEx templates
- From `software_development_lifecycle.md`: Phoenix-specific test patterns

**`prompts/git.md` #git**
- From `software_development_lifecycle.md` lines 87-114: Git workflow, branches, commits
- Universal git practices

**`prompts/llms.md` #llms**
- New file with LLM-specific guidance for prompt engineering, context management
- From WARP.md: LLM interaction patterns

### Project Build Characteristics (New Files)

**`prompts/mvp_development.md` #mvp**
- From `prioritize_work.md` lines 400-450: Early-stage development principles
- From `prioritize_work.md` lines 415-431: Anti-patterns to avoid for MVP
- MVP vs enterprise tradeoffs

**`prompts/greenfield_project.md` #greenfield**
- Greenfield-specific practices: tech stack freedom, architectural flexibility
- From various prompts: principles for new projects without legacy constraints

**`prompts/test_driven_development.md` #tdd-implementation**
- From `software_development_lifecycle.md` lines 58-86: TDD implementation workflow
- From `validate_and_fix_tests.md`: TDD execution patterns

### Technology Integration (Modified Files)

**`prompts/prioritize_work.md`** - Remove universal principles, keep EatFair-specific prioritization
**`prompts/software_development_lifecycle.md`** - Becomes EatFair-specific workflow, references universal principles
**`prompts/development_prompts.md`** - Keep as prompt collection but with proper tags and references

### Files That Stay Mostly As-Is

**Documentation (Product Domain)**
- `documentation/product_specification.md` - Pure EatFair domain
- `documentation/architectural_decision_records.md` - EatFair-specific decisions  
- `backlog_dashboard.md` - EatFair backlog management pattern

**High-Level Orchestration**
- `WARP.md` - Warp terminal specific, references AGENTS.md only
- `AGENTS.md` - Becomes tag routing and agent coordination

## Tag System Design

Each prompt file will include tags at the top:
```markdown
# Prompt Title
Tags: #tdd #quality #phoenix #mvp

Content...
```

AGENTS.md will include a mapping:
```markdown
## Prompt Tag Directory
- #tdd → `prompts/tdd_principles.md` - Core test-driven development cycle
- #phoenix → `prompts/phoenix.md` - Phoenix framework patterns  
- #feedback → `prompts/process_feedback.md` - Systematic feedback processing
- #mvp → `prompts/mvp_development.md` - MVP development characteristics
```

## Reference Update Plan

All cross-references will be updated to point to new locations:
- `software_development_lifecycle.md` → `tdd_principles.md` for TDD concepts
- `development_prompts.md` → specific categorical prompts for detailed guidance
- `WARP.md` → `AGENTS.md` for agent coordination
- `AGENTS.md` → specific prompts via tag system
