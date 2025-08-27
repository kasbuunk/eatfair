# Backlog Dashboard

**Single Source of Truth for Work Prioritization**

This dashboard contains an ordered list of all current work items. The order of items in this list **IS** the priority - no additional priority indicators are needed.

## Current Priority Order

*Items are listed in priority order from highest (top) to lowest (bottom)*

### High Priority

*(No items currently defined - this will be populated as backlog items are created)*

---

## Instructions for Use

### For Orchestrator Agents
- **Always work on the first non-done item** in the list above
- Update this dashboard when priorities change
- Add new items in their correct priority position
- Remove completed items or move them to an archive section

### For All Agents
- **Never** work on items that are not in this dashboard
- **Never** assume priority based on any other criteria
- **Always** check this dashboard for current work priorities
- Items must have a corresponding file in the `backlog/` directory with detailed specifications

### Status Management
- Status is managed within individual backlog item files using tags:
  - `#status/todo` - Not yet started
  - `#status/in_progress` - Currently being worked on  
  - `#status/blocked` - Waiting on external dependencies
  - `#status/done` - Meets all Definition of Done criteria
- This dashboard shows **priority order only**

### Link Format
Each item should be linked as: `[Brief Description](backlog/item_filename.md)`

---

**Related Documents:**
- [Definition of Done](documentation/definition_of_done.md) - Criteria for marking items complete
- [System Constitution](prompts/warp.md) - Global principles and operational rules
- [Agent Types](prompts/agents.md) - Roles and responsibilities for different agent types
