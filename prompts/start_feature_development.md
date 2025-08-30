# Start Development Work

Tags: #development #eatfair #tdd

*Auto-determine and implement the next most important work item for EatFair using the appropriate development approach.*

**Foundation**: This prompt integrates universal development principles with EatFair-specific workflow:
- **TDD Methodology**: [TDD Principles](tdd_principles.md) for test-driven development cycle
- **MVP Context**: [MVP Development](mvp_development.md) for appropriate development approach
- **Quality Standards**: [Quality Gates](quality_gates.md) for comprehensive validation
- **Phoenix Patterns**: [Phoenix Framework](phoenix.md) for technology-specific guidance

---

## 🚀 One-Liner (Most Common)

```
Implement the next highest-priority work item from PROJECT_IMPLEMENTATION.md using #tdd #phoenix #mvp principles.
```

---

## 📋 Complete Development Work Prompt

Use this when you want detailed planning and implementation:

```
Review EatFair's current status and implement the next most impactful work item.

IMPLEMENTATION PROCESS:
1. **SYNC STATUS**: Run tests and verify PROJECT_IMPLEMENTATION.md accuracy
2. **REVIEW WORK ITEMS**: Check Priority Work Items section for available work
3. **SELECT APPROACH**: Choose appropriate method based on work item type (Quality Engineering, Testing, Feature Development, Refactoring)
4. **IMPLEMENT**: Follow suitable approach with comprehensive validation
5. **UPDATE**: Sync documentation immediately upon completion

OUTPUT FORMAT:

## 📊 Current Project Health
- **Tests Status**: [Passing/failing counts with percentage]
- **MVP Progress**: [Realistic completion percentage]
- **Critical Gaps**: [Blocking issues for user adoption]
- **Ready Features**: [What actually works for users]

## 🎯 Recommended Work Item: [WORK_ITEM_NAME]
**Type**: [Quality Engineering | Feature Development | Testing | Refactoring]
**Impact**: [How this affects users/production readiness]
**Effort**: [Time estimate from work item description]
**Blocks**: [What this unblocks for production readiness]

## 🧪 Implementation Plan (Based on Work Type)

### For Quality Engineering & Testing Work
- **Analysis Framework**: Use VALIDATE_ALL_TESTS_PASS.md for comprehensive analysis
- **Test Enhancement**: Add edge cases, error conditions, production scenarios
- **Specification Validation**: Ensure tests prove specification compliance
- **Realistic Testing**: Use enhanced seed data for complex scenarios

### For Feature Development Work
- **Primary Test**: [Main user journey test file and approach]
- **TDD Steps**: Red (failing test) → Green (minimal implementation) → Refactor
- **Edge Cases**: [Error conditions and boundary tests]
- **Success Criteria**: [Specific behaviors that must work]

### For Refactoring & Technical Work
- **Current Behavior**: Preserve all existing functionality
- **Quality Improvement**: Focus on maintainability, performance, or architecture
- **Test Safety**: All existing tests must continue passing
- **Documentation**: Update technical decisions if architectural changes made

### Immediate Success Validation
- [ ] All tests pass (mix test)
- [ ] Work item completed according to its specification
- [ ] PROJECT_IMPLEMENTATION.md updated with progress
- [ ] No regressions in existing functionality
- [ ] Enhanced seed data used for realistic testing (where applicable)

## 🎯 Why This Work Item Now?
[Clear justification for prioritizing this specific work item over alternatives]

READY TO IMPLEMENT?
```

---

## Background Context

This prompt is designed to:
- **Automatically assess project state** without manual specification
- **Choose optimal next work item** based on Priority Work Items in PROJECT_IMPLEMENTATION.md
- **Provide appropriate development approach** based on work item type
- **Justify decisions** to ensure alignment with production readiness goals
- **Accelerate development** by removing decision paralysis
- **ENFORCE DOCUMENTATION DISCIPLINE** by requiring PROJECT_IMPLEMENTATION.md updates

The AI will analyze PROJECT_IMPLEMENTATION.md Priority Work Items section to understand available work, select appropriate development approach (Quality Engineering, Feature Development, Testing, Refactoring), and execute using the proper methodology.

**Available Work Item Types:**
- **Quality Engineering**: Use VALIDATE_ALL_TESTS_PASS.md framework for deep analysis
- **Feature Development**: Follow TDD approach defined in SOFTWARE_DEVELOPMENT_LIFECYCLE.md
- **Testing & Integration**: Focus on edge cases and production scenarios
- **Refactoring & Performance**: Maintain functionality while improving quality

---

*This prompt embodies the project's philosophy of production-ready quality engineering and appropriate development methodologies.*
