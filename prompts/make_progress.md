# Make Progress

*Master orchestration prompt that automatically determines the highest-priority work item, identifies its type, and executes using the appropriate development methodology.*

---

## 🎯 **Master Development Command**

**Use this single prompt to continue development:**

```
Read, understand and act on the prompt in MAKE_PROGRESS.md
```

---

## 📋 **Orchestration Framework**

This prompt will automatically:

1. **📊 Analyze Current State**
   - Run tests to verify system health
   - Read PROJECT_IMPLEMENTATION.md for work item status
   - Check PROJECT_SPECIFICATION.md for requirements context

2. **🎯 Select Next Work Item**
   - Choose highest-priority work item from PROJECT_IMPLEMENTATION.md
   - Consider dependencies and current project phase
   - Validate work item is ready for development

3. **🔍 Determine Work Type & Select Methodology**
   - **Quality Engineering** → Use VALIDATE_ALL_TESTS_PASS.md framework
   - **Feature Development** → Use TDD approach from SOFTWARE_DEVELOPMENT_LIFECYCLE.md
   - **Refactoring/Technical Debt** → Use refactoring patterns from DEVELOPMENT_PROMPTS.md
   - **Bug Fixing/Troubleshooting** → Use debugging approach from DEVELOPMENT_PROMPTS.md
   - **Testing/Integration** → Use testing patterns from DEVELOPMENT_PROMPTS.md

4. **⚡ Execute Work Using Selected Methodology**
   - Apply appropriate development approach
   - Use enhanced seed data for realistic testing
   - Follow project quality standards and patterns

5. **📝 Update Documentation**
   - Update PROJECT_IMPLEMENTATION.md with progress
   - Mark work items complete when finished
   - Set next recommended work priority

---

## 🤖 **Execution Instructions**

**STEP 1: Project Health Check**
```bash
# Run tests to verify current system state
mix test

# Expected: All tests should pass (currently 163/163 passing)
# If tests fail: Switch to debugging mode and fix failing tests first
```

**STEP 2: Work Item Analysis**
- Read PROJECT_IMPLEMENTATION.md "Priority Work Items for Production Readiness" section
- Select the first available High Priority work item (unless user specifies otherwise)
- If all High Priority items are complete, move to Medium Priority
- Validate work item has clear scope, tasks, and success criteria

**STEP 3: Work Type Detection & Methodology Selection**

| Work Type Indicators | Selected Methodology | Reference Document |
|---------------------|---------------------|-------------------|
| "Quality Engineering", "Deep Test Analysis", "Production Validation" | **Quality Engineering** | VALIDATE_ALL_TESTS_PASS.md |
| "Feature Development", "User Journey", "New Functionality" | **Test-Driven Development** | SOFTWARE_DEVELOPMENT_LIFECYCLE.md |
| "Refactoring", "Technical Debt", "Code Quality", "Performance" | **Refactoring Approach** | DEVELOPMENT_PROMPTS.md → Technical Debt Resolution |
| "Testing", "Integration Testing", "Edge Cases" | **Testing Enhancement** | DEVELOPMENT_PROMPTS.md → Test Quality Assessment |
| "Bug", "Fix", "Debug", "Troubleshoot" | **Debugging Approach** | DEVELOPMENT_PROMPTS.md → Bug Investigation |

**STEP 4: Execute Selected Methodology**
- **For Quality Engineering**: Follow VALIDATE_ALL_TESTS_PASS.md comprehensive analysis framework
- **For Feature Development**: Follow SOFTWARE_DEVELOPMENT_LIFECYCLE.md TDD approach (Red → Green → Refactor)
- **For Other Work Types**: Use appropriate prompt from DEVELOPMENT_PROMPTS.md

**STEP 5: Quality Standards (Apply to All Work Types)**
- All tests must continue passing
- Use enhanced seed data for realistic testing scenarios
- Follow Phoenix LiveView patterns from AGENTS.md
- Run `mix precommit` before completion
- Ensure work item success criteria are met

**STEP 6: Documentation Updates**
- **MANDATORY**: Update PROJECT_IMPLEMENTATION.md immediately upon completion
- Mark work item progress or completion with appropriate status (✅/🟡/🔴)
- Update any relevant test coverage documentation
- Set "Current Recommended Work" to next priority item
- Document architectural decisions in ARCHITECTURAL_DECISION_RECORDS.md if applicable

---

## 🎯 **Expected Outcomes**

After running this prompt, you should have:

1. **✅ Work Item Completed**: According to its specific success criteria
2. **✅ All Tests Passing**: No regressions introduced  
3. **✅ Documentation Updated**: PROJECT_IMPLEMENTATION.md reflects current state
4. **✅ Next Priority Clear**: Ready for future development sessions
5. **✅ Quality Standards Met**: Code follows project patterns and standards

---

## 🔧 **Methodology Reference Quick Guide**

### Quality Engineering (VALIDATE_ALL_TESTS_PASS.md)
- Deep analysis of existing tests against specification requirements
- Edge case and error condition identification
- Production scenario validation
- Cross-feature integration testing
- Use enhanced seed data for realistic testing

### Feature Development (SOFTWARE_DEVELOPMENT_LIFECYCLE.md)
- Test-Driven Development: Red (failing test) → Green (implementation) → Refactor
- User story-driven development
- Specification compliance validation
- End-to-end integration testing

### Refactoring (DEVELOPMENT_PROMPTS.md)
- Preserve existing functionality while improving code quality
- Create tests that validate current behavior
- Incremental improvements while keeping tests green
- Focus on maintainability and performance

### Testing Enhancement (DEVELOPMENT_PROMPTS.md)
- Add comprehensive test coverage for existing features
- Focus on edge cases and error conditions
- Improve test reliability and execution speed
- Validate production readiness scenarios

### Bug Fixing (DEVELOPMENT_PROMPTS.md)
- Create failing test that reproduces the bug
- Use test-driven approach to identify root cause
- Fix root cause, not symptoms
- Add regression test to prevent reoccurrence

---

## 🎪 **Project Context Awareness**

This prompt automatically adapts to EatFair's current state:

- **Current Phase**: Feature complete, quality engineering required (75% MVP completion)
- **Test Health**: 163/163 tests passing (0.9 seconds execution time)
- **Priority Focus**: Production readiness through comprehensive quality validation
- **Available Resources**: Enhanced seed data with diverse user scenarios
- **Quality Standards**: Production-ready error handling, specification compliance, real-world testing

---

**🚀 ONE COMMAND TO RULE THEM ALL:**

```
Read, understand and act on the prompt in MAKE_PROGRESS.md
```

*This single command will analyze the project state, select the appropriate work item, determine the right methodology, and execute development work using EatFair's established quality standards and development practices.*
