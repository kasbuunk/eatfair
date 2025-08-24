# Start Feature Development

*Use this prompt to automatically determine and begin the next most important feature for EatFair.*

---

## Quick Start Prompt

Copy and paste this into any conversation to automatically progress the project:

```
Review the current project status and determine the next best feature to implement.

PROCESS:
1. Check PROJECT_IMPLEMENTATION.md for current progress
2. Identify highest priority missing MVP feature from PROJECT_SPECIFICATION.md
3. Consider development dependencies and logical implementation order
4. Suggest specific feature to implement next
5. Justify why this feature should be prioritized now
6. Propose comprehensive TDD approach and test strategy

OUTPUT FORMAT:
## Current Project Status
- [Summary of completed features]
- [Current MVP completion percentage]
- [Blocked or in-progress items]

## Recommended Next Feature: [FEATURE_NAME]
**Priority:** MVP Critical / Phase 2 / Nice to Have
**Estimated Effort:** [Small/Medium/Large]
**Dependencies:** [Any prerequisites or blockers]

## Justification
- [Why this feature should be next]
- [How it unblocks other features]
- [User value it provides]
- [Risk mitigation benefits]

## TDD Implementation Approach
### 1. End-to-End Test Strategy
- [Primary user journey to test]
- [Test file location and naming]
- [Key interactions to verify]

### 2. Implementation Steps
1. [Write failing E2E test]
2. [Create minimal implementation]
3. [Add edge case tests]
4. [Refactor for quality]

### 3. Success Criteria
- [Specific behaviors that must work]
- [Performance requirements]
- [Error handling scenarios]

### 4. Documentation Updates
- [Which documents need updates]
- [Progress tracking changes]

Ready to proceed with implementation?
```

---

## Background Context

This prompt is designed to:
- **Automatically assess project state** without manual specification
- **Choose optimal next feature** based on current progress and dependencies  
- **Provide complete TDD approach** following project standards
- **Justify decisions** to ensure alignment with PROJECT_SPECIFICATION.md
- **Accelerate development** by removing decision paralysis

The AI will analyze PROJECT_IMPLEMENTATION.md to understand current status, reference PROJECT_SPECIFICATION.md for requirements, and propose the most logical next step following the TDD approach defined in SOFTWARE_DEVELOPMENT_LIFECYCLE.md.

---

*This prompt embodies the project's philosophy of pragmatic MVP excellence and test-driven development.*
