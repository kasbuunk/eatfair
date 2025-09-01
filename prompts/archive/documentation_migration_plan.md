# Documentation Migration Plan: documentation/ → prompts_config/

## Overview
This document provides the master plan for reorganizing `documentation/` files into the `prompts_config/` directory structure according to WARP.md principles of Single Source of Truth and modular prompt architecture.

## File Inventory and Analysis

### Current documentation/ Files (11 files analyzed)

| File | Size (est.) | Type | Purpose | Overlap with Existing |
|------|-------------|------|---------|----------------------|
| `admin_schema_analysis.md` | Large (353 lines) | Technical Reference | Database schema documentation for admin dashboard | Some overlap with tech_stack.md |
| `architectural_decision_records.md` | Large (353 lines) | Process/Architecture | ADR chronology and design decisions | None |
| `definition_of_done.md` | Small (10 lines) | Process | Completion criteria checklist | Some overlap with quality_standards.md |
| `development_interaction_notes.md` | Large (224 lines) | Process/Philosophy | Development mindset and interaction patterns | Some overlap with workflows.md |
| `development_log.md` | Extra Large (1400+ lines) | Project Status | Historical development log with conversation transcripts | None |
| `features_completed.md` | Large (146 lines) | Project Status | Feature completion documentation | None |
| `legacy_implementation_log.md` | Extra Large (1400+ lines) | Project Status | Implementation progress tracking | None |
| `phoenix_elixir_reference.md` | Extra Large (1000+ lines) | Technical Reference | Phoenix/Elixir patterns and conventions | Major overlap with tech_stack.md |
| `product_specification.md` | Extra Large (1000+ lines) | Product | Complete product requirements specification | Some overlap with project_context.md |
| `security_incident_google_maps_api_key_exposure.md` | Medium (102 lines) | Incident Report | Security incident post-mortem | None |
| `skipped_tests_audit.md` | Small (66 lines) | Quality/Process | Analysis of skipped tests in codebase | Some overlap with quality_standards.md |

### Current prompts_config/ Files (6 files)

| File | Purpose | Status |
|------|---------|---------|
| `README.md` | Directory purpose and usage guide | ✅ Current |
| `backlog_management.md` | Backlog workflow configuration | ✅ Current |
| `project_context.md` | Business domain context | ✅ Current |
| `quality_standards.md` | Quality and testing standards | ✅ Current |
| `tech_stack.md` | Technical patterns and conventions | ✅ Current |
| `workflows.md` | Development workflow configuration | ✅ Current |

## Migration Matrix

| Source File | Content Type | Integration Mode | Target Location(s) | Rationale |
|-------------|--------------|-------------------|-------------------|-----------|
| `admin_schema_analysis.md` | Technical Reference | **Partial Extract** | `tech_stack.md` + archive | Extract reusable DB schema patterns; archive full analysis |
| `architectural_decision_records.md` | Architecture | **New File + Archive** | `prompts_config/architecture.md` + `docs/adr/` | Create ADR template; move chronology to docs/adr/ |
| `definition_of_done.md` | Process | **Merge** | `quality_standards.md` + `workflows.md` | Small checklist integrates well |
| `development_interaction_notes.md` | Process/Philosophy | **Merge** | `workflows.md` | Contributor interaction guidance |
| `development_log.md` | Project Status | **Archive** | `docs/archive/` | Too large for prompts; historical value only |
| `features_completed.md` | Project Status | **Archive** | `docs/archive/` | Too large for prompts; historical value only |
| `legacy_implementation_log.md` | Project Status | **Summarize + Archive** | `project_context.md` + `docs/archive/` | Extract key metrics; archive details |
| `phoenix_elixir_reference.md` | Technical Reference | **Merge** | `tech_stack.md` | Major overlap; consolidate technical patterns |
| `product_specification.md` | Product | **Split** | `project_context.md` + `prompts_config/product_requirements.md` | Vision vs. detailed requirements |
| `security_incident_google_maps_api_key_exposure.md` | Incident Report | **New File + Archive** | `prompts_config/security.md` + `docs/security_incidents/` | Extract security patterns; archive incident |
| `skipped_tests_audit.md` | Quality/Process | **Merge** | `quality_standards.md` | Test audit rules fit quality standards |

## Implementation Plan

### Phase 1: Setup and Archive Directory Creation
1. Create `docs/` directory with subdirectories:
   - `docs/archive/` - Historical documents 
   - `docs/adr/` - Architectural Decision Records
   - `docs/security_incidents/` - Security incident reports
2. Create `docs/README.md` explaining directory structure

### Phase 2: Technical Reference Consolidation
1. **Merge phoenix_elixir_reference.md → tech_stack.md**
   - Extract unique patterns and conventions
   - Resolve overlaps and contradictions
   - Maintain EatFair-specific customizations
2. **Extract admin_schema_analysis.md patterns → tech_stack.md**  
   - Add database schema patterns
   - Add admin dashboard architectural guidance
   - Archive full analysis in `docs/archive/`

### Phase 3: Process and Quality Integration
1. **Merge definition_of_done.md → quality_standards.md**
   - Add DoD checklist to quality gates section
   - Reference from workflow documentation
2. **Merge development_interaction_notes.md → workflows.md**
   - Add "Contributor Interaction" section
   - Preserve development philosophy and patterns
3. **Merge skipped_tests_audit.md → quality_standards.md**
   - Add test audit rules and guidelines
   - Update test management standards

### Phase 4: Architecture and Security
1. **Create prompts_config/architecture.md**
   - Extract ADR template from architectural_decision_records.md
   - Add architectural guidance for prompts
   - Move full ADR chronology to `docs/adr/`
2. **Create prompts_config/security.md**
   - Extract security patterns from incident report
   - Add security regression checklist
   - Archive incident in `docs/security_incidents/`

### Phase 5: Product Requirements Split
1. **Enhance project_context.md** 
   - Add product vision from product_specification.md
   - Summarize key metrics from legacy_implementation_log.md
   - Keep business context focused
2. **Create prompts_config/product_requirements.md**
   - Extract detailed requirements from product_specification.md
   - Structure for reference by #context_intake and #feature_dev prompts
   - Link to backlog items for Single Source of Truth

### Phase 6: Large Document Archival  
1. **Archive large status documents**
   - Move development_log.md, features_completed.md, legacy_implementation_log.md to `docs/archive/`
   - Create summary in `docs/archive/README.md`
2. **Create redirect stubs**
   - Replace original files with single-line redirects
   - Preserve reference paths

### Phase 7: Prompt Enhancement
1. **Update prompts/ files with new configurations**
   - Reference new prompts_config files  
   - Add architecture.md and security.md to relevant prompts
   - Update examples and patterns
2. **Update WARP.md navigation**
   - Add references to new configuration files
   - Update Agent Navigation Guide

### Phase 8: Quality Assurance
1. **Validate all links and references**
2. **Test prompt functionality with new structure** 
3. **Peer review against WARP.md principles**
4. **Create migration changelog**

## Single Source of Truth Validation

### Potential Duplications to Resolve
1. **Technical Patterns**: phoenix_elixir_reference.md vs tech_stack.md
2. **Quality Standards**: Multiple references to testing approaches
3. **Product Vision**: product_specification.md vs project_context.md  
4. **Development Philosophy**: development_interaction_notes.md vs workflows.md

### Resolution Strategy
- **Consolidate overlapping content** into appropriate prompts_config files
- **Create explicit cross-references** instead of duplicating content
- **Archive detailed documentation** while preserving actionable guidance
- **Update prompts** to reference unified configurations

## Expected Outcomes

### Benefits
- ✅ **Reduced prompt context pollution** (remove 1000+ line documents)
- ✅ **Enhanced prompt specificity** (project-specific configurations)
- ✅ **Single Source of Truth compliance** (eliminate duplications)
- ✅ **Improved maintainability** (modular, focused configurations)
- ✅ **Preserved historical context** (archive large logs)

### File Count Changes
- **documentation/ files**: 11 → 0 (all migrated or archived)  
- **prompts_config/ files**: 6 → 8-10 (new architecture.md, security.md, product_requirements.md)
- **docs/ files**: 0 → 15+ (archives, ADRs, incident reports)

This plan maintains historical value while optimizing for prompt effectiveness and WARP.md compliance.
