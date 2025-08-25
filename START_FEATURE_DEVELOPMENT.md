# Start Feature Development

*Auto-determine and implement the next most important feature for EatFair using our proven TDD approach.*

---

## 🚀 One-Liner (Most Common)

```
Determine and implement the next MVP-critical feature using TDD approach.
```

---

## 📋 Complete Feature Development Prompt

Use this when you want detailed planning and implementation:

```
Review EatFair's current status and implement the next most impactful feature.

IMPLEMENTATION PROCESS:
1. **SYNC STATUS**: Run tests and verify PROJECT_IMPLEMENTATION.md accuracy
2. **ANALYZE GAPS**: Compare implementation vs PROJECT_SPECIFICATION.md requirements  
3. **PRIORITIZE**: Select highest-impact missing MVP feature
4. **IMPLEMENT**: Follow TDD approach with comprehensive tests
5. **UPDATE**: Sync documentation immediately upon completion

OUTPUT FORMAT:

## 📊 Current Project Health
- **Tests Status**: [Passing/failing counts with percentage]
- **MVP Progress**: [Realistic completion percentage]
- **Critical Gaps**: [Blocking issues for user adoption]
- **Ready Features**: [What actually works for users]

## 🎯 Recommended Feature: [FEATURE_NAME]
**Impact**: [How this affects users/business]
**Effort**: [Small: <4h, Medium: 1-2 days, Large: 3+ days]
**Blocks**: [What this unblocks for users]

## 🧪 TDD Implementation Plan
### Test Strategy
- **Primary Test**: [Main user journey test file and approach]
- **Edge Cases**: [Error conditions and boundary tests]
- **Success Criteria**: [Specific behaviors that must work]

### Implementation Steps
1. **Red**: Write failing end-to-end test
2. **Green**: Implement minimal working solution
3. **Blue**: Add comprehensive test coverage
4. **Refactor**: Improve code quality while tests stay green

### Immediate Success Validation
- [ ] All tests pass (mix test)
- [ ] Feature works as specified in PROJECT_SPECIFICATION.md
- [ ] PROJECT_IMPLEMENTATION.md updated with progress
- [ ] No regressions in existing functionality

## 🎯 Why This Feature Now?
[Clear justification for prioritizing this specific feature over alternatives]

READY TO IMPLEMENT?
```

---

## Background Context

This prompt is designed to:
- **Automatically assess project state** without manual specification
- **Choose optimal next feature** based on current progress and dependencies  
- **Provide complete TDD approach** following project standards
- **Justify decisions** to ensure alignment with PROJECT_SPECIFICATION.md
- **Accelerate development** by removing decision paralysis
- **ENFORCE DOCUMENTATION DISCIPLINE** by requiring PROJECT_IMPLEMENTATION.md updates

The AI will analyze PROJECT_IMPLEMENTATION.md to understand current status, reference PROJECT_SPECIFICATION.md for requirements, and propose the most logical next step following the TDD approach defined in SOFTWARE_DEVELOPMENT_LIFECYCLE.md.

---

*This prompt embodies the project's philosophy of pragmatic MVP excellence and test-driven development.*
