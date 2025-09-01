# EatFair Backlog Management Configuration

**Reference**: This file is referenced from WARP.md and AGENTS.md

This file provides EatFair-specific backlog management implementation that follows the universal Single Source of Truth principles from WARP.md.

## Priority System

### Single Source of Truth
- **File**: `backlog_dashboard.md` in project root
- **Format**: Ordered list where position determines priority
- **Update Trigger**: Any change in work priority or completion status

### Directory Structure
```
backlog/                           # Individual backlog item specifications
├── 20250827174200_performance_optimization.md
├── 20250827174300_enhanced_error_handling_ux.md
└── [YYYYMMDDHHMMSS_descriptive_name.md]

backlog_dashboard.md              # Priority-ordered list (single source of truth)
```

### Backlog Item File Naming
- **Format**: `YYYYMMDDHHMMSS_descriptive_name.md`
- **Timestamp**: Creation datetime for unique identification
- **Description**: Lowercase with underscores, descriptive but concise

## Status Management

### Required Status Tags
Every backlog item MUST have exactly one status tag:
- `#status/todo` - Not yet started
- `#status/in_progress` - Currently being worked on
- `#status/blocked` - Waiting on external dependencies  
- `#status/done` - Meets all Definition of Done criteria

### Status Update Triggers
Update backlog item status when:
- **Starting work**: Change from `#status/todo` to `#status/in_progress`
- **Encountering blockers**: Change to `#status/blocked` with blocker details
- **Making significant progress**: Add progress notes to item file
- **Completing work**: Change to `#status/done` when all acceptance criteria met

### Priority Order Updates
Update `backlog_dashboard.md` when:
- New work items are created
- Business priorities shift
- Dependencies change work order
- Items are completed or blocked

## EatFair-Specific Work Categories

### Feature Development Items
Items requiring comprehensive implementation:
- User-facing functionality changes
- New business logic implementation  
- Database schema modifications
- Integration with external services

**Estimated Effort**: Typically 1-5 days of development work

### Enhancement Items  
Items improving existing functionality:
- Performance optimizations
- User experience improvements
- Error handling enhancements
- Accessibility improvements

**Estimated Effort**: Typically 0.5-2 days of development work

### Bug Fix Items
Items addressing defects:
- Production issues
- Test failures
- Integration problems
- Data inconsistencies

**Estimated Effort**: Varies based on complexity and impact

## Documentation Requirements

### Individual Backlog Items
Each backlog item file must contain:
```markdown
# Item Title

**Status**: #status/todo
**Priority**: High/Medium/Low
**Estimated Effort**: X days
**Dependencies**: [List any blockers]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Implementation Notes
[Technical approach, architecture considerations]

## Testing Requirements  
[Test coverage expectations]

## Definition of Done
[Specific completion criteria]
```

### Progress Tracking
Update items with:
- Progress notes as work advances
- Blocker details if work gets stuck
- Completion notes when done
- Links to relevant commits, PRs, or documentation

## Integration with Development Workflow

### TDD Workflow Integration
1. **Start Phase**: Check `backlog_dashboard.md` for current priority
2. **During Development**: Update item status and add progress notes
3. **Completion Phase**: Mark as `#status/done` and update priority order

### Commit Integration
- Reference backlog items in commit messages
- Link significant commits back to backlog items
- Update backlog status concurrently with code changes

### Documentation Updates
When completing backlog items:
- Update `documentation/legacy_implementation_log.md`
- Mark features as complete with test references
- Document architectural decisions in ADRs
- Update overall project progress metrics

## Key File References

### Primary Files
- `backlog_dashboard.md` - Priority-ordered work list (single source of truth)
- `backlog/` - Individual item specifications
- `documentation/definition_of_done.md` - Completion criteria
- `documentation/legacy_implementation_log.md` - Progress tracking

### Supporting Files
- `documentation/product_specification.md` - Feature requirements context
- `documentation/architectural_decision_records.md` - Technical decisions
- `documentation/features_completed.md` - Completed work reference

This backlog management approach ensures clear prioritization, progress tracking, and alignment with EatFair's development workflow.
