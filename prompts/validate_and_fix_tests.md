# Test Validation & Fix Prompt

**Purpose:** Systematically validate that all tests pass by ensuring production code correctly implements project specifications and test requirements.

## Quick Usage

```
"Run comprehensive test validation to ensure all tests pass and production code aligns with project specifications"
```

## Comprehensive Test Validation Process

### Phase 1: Discovery & Assessment

1. **Run Complete Test Suite**
   ```bash
   mix test --verbose
   ```
   - Identify all failing tests with specific error messages
   - Categorize failures by type (compilation, assertion, timeout, etc.)
   - Note any warnings or deprecation notices

2. **Analyze Test Coverage**
   ```bash
   mix test --cover
   ```
   - Review coverage report for untested code paths
   - Identify critical business logic with insufficient coverage

3. **Review Project Specifications**
   - Read `documentation/product_specification.md` for business requirements
   - Check `documentation/legacy_implementation_log.md` for expected functionality
   - Review `documentation/architectural_decision_records.md` for technical constraints

### Phase 2: Systematic Validation & Correction

#### For Each Failing Test:

1. **Understand Test Intent**
   - Read the test description and assertions carefully
   - Identify what behavior is being validated
   - Check if test aligns with product specification
   - Verify test data setup and expected outcomes

2. **Analyze Production Code**
   - Locate the production code being tested
   - Compare actual implementation with test expectations
   - Check for missing functions, incorrect logic, or type mismatches
   - Verify database schema matches test assumptions

3. **Identify Root Cause**
   - **Missing Implementation**: Function/module doesn't exist
   - **Logic Error**: Implementation doesn't match specification
   - **Data Mismatch**: Test data doesn't match production assumptions
   - **Schema Issue**: Database structure doesn't support test scenario
   - **Dependency Problem**: Missing or incorrect dependencies
   - **Test Error**: Test itself is incorrect or outdated

4. **Apply Targeted Fix**
   - **Code Fix**: Implement missing functionality or correct logic
   - **Schema Fix**: Add migrations or update database structure  
   - **Test Fix**: Update test to match correct specification
   - **Dependency Fix**: Add or update required packages

### Phase 3: Verification & Integration

1. **Verify Individual Fix**
   ```bash
   mix test test/path/to/specific_test.exs
   ```
   - Ensure the specific test now passes
   - Check that fix doesn't break related functionality

2. **Run Affected Test Suite**
   ```bash
   mix test test/path/to/module/
   ```
   - Verify no regressions in related tests
   - Ensure integrated functionality still works

3. **Full Regression Check**
   ```bash
   mix test
   ```
   - Confirm all tests pass
   - Verify no new failures introduced

## EatFair-Specific Validation Checklist

### Phoenix/LiveView Patterns
- [ ] LiveView mounts correctly with proper assigns
- [ ] Event handlers match expected function signatures
- [ ] Components receive and validate required assigns
- [ ] Navigation and routing work as specified

### Business Logic Validation  
- [ ] User authentication and authorization work correctly
- [ ] Restaurant discovery matches filtering specifications
- [ ] Booking system handles all required scenarios
- [ ] Admin functions provide expected capabilities

### Data Layer Validation
- [ ] All Ecto schemas match database structure
- [ ] Changesets validate according to business rules
- [ ] Queries return expected data formats
- [ ] Database seeds create valid test data

### UI/UX Validation
- [ ] Forms submit and validate correctly
- [ ] Error messages display appropriately
- [ ] Success flows complete as designed
- [ ] Responsive design works on all breakpoints

## Common EatFair Fix Patterns

### Authentication Scope Issues
```elixir
# Problem: Using @current_user instead of @current_scope.user
def show(socket, _params) do
  user = socket.assigns.current_user  # ❌ Incorrect
  # Fix:
  user = socket.assigns.current_scope.user  # ✅ Correct
end
```

### LiveView Memory Issues
```elixir
# Problem: Using assigns for large collections
assign(socket, :restaurants, restaurants)  # ❌ Memory heavy

# Fix: Use streams for collections
stream(socket, :restaurants, restaurants)  # ✅ Efficient
```

### Component Usage
```elixir
# Problem: Custom components instead of built-ins
<custom-input />  # ❌ Avoid external dependencies

# Fix: Use Phoenix built-in components
<.input name="email" type="email" />  # ✅ Use built-ins
```

## Quality Assurance Checklist

### Before Committing Fixes
- [ ] All tests pass: `mix test`
- [ ] No compilation warnings: `mix compile --warnings-as-errors`
- [ ] Code formatted: `mix format`
- [ ] Static analysis clean: `mix credo`
- [ ] Dependencies audited: `mix deps.audit`

### Documentation Updates
- [ ] Update `PROJECT_IMPLEMENTATION.md` with new test coverage
- [ ] Document any architectural changes
- [ ] Note any specification clarifications discovered
- [ ] Update progress percentages based on working functionality

## Escalation Protocol

### When Test Intent is Unclear
1. Check product specification for business requirements
2. Review legacy implementation log for historical context
3. Look for related tests that might clarify expected behavior
4. Document assumption and implement most logical interpretation
5. Flag for specification clarification in next review

### When Production Code Conflicts with Specification
1. Prioritize product specification as source of truth
2. Update production code to match specification
3. Document the discrepancy in architectural decision records
4. Update any dependent tests to match corrected implementation

### When Multiple Solutions are Possible
1. Choose solution that best aligns with established patterns
2. Prefer simple, maintainable implementations
3. Consider performance and scalability implications
4. Document the decision rationale

## Success Criteria

✅ **All tests pass without errors or warnings**
✅ **Production code implements specified business requirements**  
✅ **Test coverage meets or exceeds previous levels**
✅ **No regressions introduced in working functionality**
✅ **Documentation updated to reflect current implementation**
✅ **Code follows established Phoenix/Elixir patterns**
✅ **All quality gates pass (formatting, linting, compilation)**

## Post-Validation Actions

1. **Commit Changes**
   ```bash
   git add specific/files/changed
   git commit -m "fix(tests): ensure all tests pass and align with specifications"
   ```

2. **Update Implementation Log**
   - Mark features as ✅ Complete where all tests now pass
   - Update test coverage percentages
   - Document any new functionality discovered

3. **Run Precommit Validation**
   ```bash
   mix precommit
   ```
   - Final verification that all quality gates pass
   - Ensures commit meets project standards

This prompt ensures systematic validation of test failures while maintaining alignment with EatFair's product vision and technical architecture.
