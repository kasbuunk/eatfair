# Validate All Tests Pass

**Purpose**: Ensure all tests pass by verifying production code correctness and alignment with project specification

## Full Prompt

Systematically validate that all tests pass and production code meets specifications:

**1. Test Execution Validation**
- Apply #run_all_tests to execute complete test suite
- Verify all unit tests pass without errors or failures
- Ensure integration tests validate system interactions correctly
- Confirm end-to-end tests cover complete user workflows

**2. Production Code Verification**
- Compare implementation against project specification requirements
- Verify business logic aligns with documented specifications
- Ensure all acceptance criteria are satisfied
- Check that edge cases and error conditions are properly handled

**3. Test Coverage and Quality**
- Verify test coverage meets project standards
- Ensure tests are meaningful and test actual behavior
- Check that tests are independent and don't rely on execution order
- Validate test data and fixtures are appropriate

**4. Specification Alignment**
- Cross-reference implementation with project specification
- Verify all required features are implemented correctly
- Ensure API contracts match specification documents
- Confirm user interface matches design requirements

**5. Quality Gates Validation**
- Apply #validation to verify comprehensive quality checks
- Ensure code follows project conventions and best practices
- Verify security requirements are met
- Confirm performance criteria are satisfied

**6. Corrective Actions**
- If tests fail, apply #debug_bug to identify and fix issues
- If specification misalignment found, apply #clarify_requirements
- Update tests if specifications have changed
- Apply #refactor if code quality needs improvement

Use this validation process before:
- Merging code changes
- Releasing features
- Deploying to production
- Major milestone reviews

## Configuration Points

- **Test Suite Scope**: Which tests must pass for validation
- **Coverage Thresholds**: Minimum test coverage requirements
- **Quality Standards**: Code quality and specification compliance criteria
- **Approval Process**: Who must review and approve validation results

## Related Prompts

**Prerequisites**: #run_all_tests - Execute comprehensive test suite  
**Complements**: #validation, #code_review - Comprehensive quality checks  
**Follows**: #merge_deploy - Deploy validated changes
