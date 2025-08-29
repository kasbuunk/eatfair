# Backlog Dashboard

**Single Source of Truth for Work Prioritization**

This dashboard contains an ordered list of all current work items. The order of items in this list **IS** the priority - no additional priority indicators are needed.

## Current Priority Order

*Items are listed in priority order from highest (top) to lowest (bottom)*

### High Priority

1. [Order Delivery Tracking Journey](backlog/20250829153620_order_delivery_tracking_journey.md)
2. [Test Validation Prompt Enhancement](backlog/20250827175200_test_validation_prompt_enhancement.md)
3. [Performance Optimization](backlog/20250827174200_performance_optimization.md)
4. [Enhanced Error Handling & User Experience](backlog/20250827174300_enhanced_error_handling_ux.md)
5. [Accessibility & Dark Mode Enhancement](backlog/20250827174700_accessibility_dark_mode.md)

### Medium Priority

6. [Enhanced Location-Based Restaurant Discovery](backlog/20250827174400_enhanced_location_discovery.md)
7. [User Feedback Collection System](backlog/20250827174800_user_feedback_system.md)
8. [Platform Donation System](backlog/20250827174900_platform_donation_system.md)

### Lower Priority

9. [Advanced Multi-Select Filter System](backlog/20250827174600_advanced_multi_select_filters.md)
10. [Interactive Map-Based Restaurant Discovery](backlog/20250827174500_interactive_map_discovery.md)
11. [Courier Interface & Delivery Management](backlog/20250827175000_courier_delivery_management.md)
12. [Restaurant Owner Analytics Dashboard](backlog/20250827175100_restaurant_analytics_dashboard.md)

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
- [System Constitution](WARP.md) - Global principles and operational rules
- [Agent Types](AGENTS.md) - Roles and responsibilities for different agent types
