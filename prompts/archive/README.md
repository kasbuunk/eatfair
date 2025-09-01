# EatFair Documentation Archive

This directory contains historical and reference documentation that has been moved out of the main `prompts/config/` structure to avoid polluting prompt context while preserving important historical value.

## Directory Structure

### `archive/`
Historical documentation that was too large for prompt integration but provides important development context:
- `development_log.md` - Complete development history with conversation transcripts
- `features_completed.md` - Historical feature completion documentation
- `legacy_implementation_log.md` - Detailed implementation progress tracking
- `admin_schema_analysis.md` - Complete database schema analysis for admin dashboard

### `adr/`
Architectural Decision Records chronology moved from `documentation/architectural_decision_records.md`:
- Individual ADR files for each major architectural decision
- Referenced by `prompts/config/architecture.md` for template and patterns

### `security_incidents/`
Security incident reports and post-mortems:
- `google_maps_api_key_exposure_2025-08-28.md` - Complete incident report
- Referenced by `prompts/config/security.md` for patterns and checklists

## Usage

### For Development Teams
These archives provide:
- **Complete project history** - Full development context and decisions
- **Incident learning** - Security and operational incident patterns
- **Architecture evolution** - How major technical decisions were made

### For AI Agents
- **Do not load these files directly** - They exceed token budgets
- **Reference summaries** in `prompts/config/` files instead
- **Link to specific sections** when deep historical context is needed

## Maintenance

These files should be:
- ✅ **Preserved as-is** for historical accuracy
- ✅ **Referenced by summaries** in prompts_config files
- ✅ **Updated only for factual corrections** or link updates
- ❌ **Not used directly in prompt context** due to size

## Quick Navigation

- **Current system guidance** → Use `prompts/config/` files
- **Historical context** → Use `docs/archive/` files  
- **Architecture decisions** → Use `docs/adr/` files
- **Security patterns** → Use `docs/security_incidents/` files
- **Active development** → Use `backlog/` and `prompts/` directories

This structure maintains Single Source of Truth principles while optimizing for prompt effectiveness.
