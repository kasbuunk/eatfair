# Validate and Fix Tests

**Purpose**: Systematically validate test suite integrity and fix any issues to ensure reliable testing

## Full Prompt

Validate test suite health and fix issues:

**1. Test Suite Validation**
- Apply #run_all_tests to identify failing or broken tests
- Check for tests that pass inconsistently (flaky tests)
- Verify test isolation and independence
- Identify tests that are slow or resource-intensive

**2. Test Quality Assessment**
- Review test coverage and identify gaps
- Ensure tests are testing meaningful behavior, not implementation details
- Verify test assertions are specific and appropriate
- Check that test data and fixtures are realistic and maintainable

**3. Test Code Quality**
- Apply #code_review principles to test code
- Ensure test code follows project conventions
- Remove duplicate test logic and extract common utilities
- Verify test organization and naming conventions

**4. Fix Failing Tests**
- Apply #debug_bug to investigate test failures
- Determine if failure is due to:
  - Broken production code (fix the code)
  - Outdated test expectations (update the test)
  - Environmental issues (fix test setup)
  - Test logic errors (fix the test)

**5. Improve Test Reliability**
- Fix flaky tests by addressing timing issues or dependencies
- Improve test isolation by removing shared state
- Add missing error handling in test setup and teardown
- Enhance test data management for consistency

**6. Test Suite Optimization**
- Optimize slow tests without compromising coverage
- Parallelize independent tests where possible
- Remove obsolete or redundant tests
- Improve test feedback and error reporting

**7. Documentation and Maintenance**
- Document test setup requirements and dependencies
- Create troubleshooting guides for common test issues
- Establish test maintenance procedures
- Set up monitoring for test suite health

Use testing frameworks from: prompts/config/tech_stack.md  
Follow test quality standards from: prompts/config/quality_standards.md

## Configuration Points

- **Test Frameworks**: Project-specific testing tools and utilities
- **CI Integration**: How tests run in continuous integration
- **Performance Thresholds**: Acceptable test execution times
- **Maintenance Procedures**: Regular test suite health checks

## Related Prompts

**Prerequisites**: #run_all_tests - Identify test issues  
**Complements**: #debug_bug, #refactor - Fix test problems  
**Follows**: #validation - Verify test suite reliability
