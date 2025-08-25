# Validate All Tests Pass

*Use this prompt to ensure all tests are passing and production code correctly aligns with the project specification.*

---

## Complete Test Validation Prompt

Copy and paste this into any conversation to validate the entire codebase:

```
Ensure all tests pass and verify that production code correctly aligns with the project specification.

VALIDATION PROCESS:
1. **RUN FULL TEST SUITE**: Execute `mix test --trace` to see detailed test results
2. **ANALYZE FAILING TESTS**: If any tests fail, understand why and fix the issues
3. **VERIFY FEATURE COMPLETENESS**: Check that implemented features fully satisfy PROJECT_SPECIFICATION.md requirements
4. **VALIDATE BUSINESS LOGIC**: Ensure code correctly implements the specified behavior (not just any behavior)
5. **CHECK SPECIFICATION ALIGNMENT**: Compare what tests validate vs what specification requires
5. **CHECK TEST COVERAGE**: Confirm all critical paths are covered by passing tests
6. **UPDATE DOCUMENTATION**: Sync PROJECT_IMPLEMENTATION.md with actual working features

OUTPUT FORMAT:
## Test Suite Results
- **Total Tests**: [Number of tests]
- **Passing**: [Number passing]
- **Failing**: [Number failing]
- **Skipped**: [Number skipped]
- **Test Execution Time**: [Total runtime]

## Failing Test Analysis
For each failing test:
- **Test Name**: [Name and file location]
- **Failure Reason**: [Why it's failing]
- **Root Cause**: [Underlying issue]
- **Fix Strategy**: [How to resolve it]

## Specification Alignment Check
- **Features Specified**: [What PROJECT_SPECIFICATION.md requires]
- **Features Implemented**: [What actually works based on passing tests]
- **Gaps Identified**: [Missing or incomplete functionality]
- **Overimplementation**: [Features built beyond specification]

## Production Code Quality
- **Business Logic Correctness**: [Does code do what spec says it should?]
- **Error Handling**: [Are edge cases properly handled?]
- **Data Validation**: [Is user input properly validated?]
- **Security Considerations**: [Are security requirements met?]

## Recommendations
- **Immediate Fixes**: [Critical issues that must be addressed]
- **Technical Debt**: [Code that works but needs improvement]
- **Missing Tests**: [Functionality that lacks test coverage]
- **Documentation Updates**: [What needs to be updated in PROJECT_IMPLEMENTATION.md]

REQUIREMENTS:
- Fix ALL failing tests before marking any feature as complete
- Ensure production code behavior matches specification exactly
- Update PROJECT_IMPLEMENTATION.md to reflect only actually working features
- Document any assumptions or deviations from specification
```

---

## When to Use This Prompt

Use this validation prompt:
- **Before major milestones** to ensure quality standards
- **After significant development** to verify nothing broke
- **Before deployment** to confirm readiness for production
- **During code reviews** to validate implementation correctness
- **When test results seem inconsistent** with expected functionality
- **Before updating PROJECT_IMPLEMENTATION.md** to ensure accuracy

## Quality Standards

### Test Quality Requirements:
1. **All tests must pass** - No exceptions for "complete" features
2. **Tests must validate specification requirements** - Not just any functionality, but what's actually specified
3. **Tests must cover specification scenarios** - Including business rules and edge cases from specification
4. **Fast execution** - Test suite should run in under 30 seconds for quick feedback
5. **Clear failure messages** - When tests fail, the reason should be obvious

### Production Code Requirements:
1. **Specification compliance** - Code must do exactly what PROJECT_SPECIFICATION.md says
2. **Error handling** - Graceful handling of invalid inputs and edge cases
3. **Data integrity** - Proper validation and constraints
4. **Security** - Authentication, authorization, and input sanitization

### Documentation Requirements:
1. **Evidence-based** - Only mark features complete if tests prove they work
2. **Accurate progress tracking** - Realistic assessment of what's actually done
3. **Technical debt transparency** - Document shortcuts and limitations
4. **Clear next steps** - What needs to be done to truly complete features

---

## Integration with Development Workflow

This validation prompt works with other project prompts:
- **Use BEFORE START_FEATURE_DEVELOPMENT.md** to get accurate current state
- **Use AFTER feature development** to confirm implementation quality
- **Use WITH UPDATE_PROJECT_DOCUMENTATION.md** to ensure accuracy
- **Use BEFORE deployment preparation** to verify production readiness

---

## Common Issues and Solutions

### Flaky Tests
- **Problem**: Tests pass sometimes, fail other times
- **Solution**: Identify race conditions, improve test isolation
- **Prevention**: Use deterministic test data, proper setup/teardown

### Tests Pass But Feature Doesn't Work
- **Problem**: Tests are too narrow or mock too much
- **Solution**: Add integration tests, test with real data
- **Prevention**: Focus on user journey testing

### Specification vs Implementation Mismatch
- **Problem**: Code works differently than specification says
- **Solution**: Either fix code or update specification (with justification)
- **Prevention**: Reference specification in test descriptions

---

*This prompt ensures that "working" features actually work as specified and are proven by comprehensive tests.*
