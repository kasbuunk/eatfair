# EatFair Quality Standards

This file defines EatFair-specific quality standards that customize the behavior of quality-related prompts.

## Test-Driven Development Standards

### Test Coverage Requirements
- **End-to-End Tests**: 100% coverage of critical user journeys (restaurant owner flows, consumer ordering, payment processing)
- **Integration Tests**: All context boundaries and external service integrations
- **Unit Tests**: Complex business logic (pricing calculations, delivery radius logic, commission calculations)
- **Performance Tests**: All user-facing operations must complete in <200ms

### Test Quality Standards
- **Test Execution Speed**: Full test suite must complete in <30 seconds
- **Individual Test Speed**: Each test must complete in <1 second
- **Test Reliability**: Zero flaky tests - all tests must pass consistently
- **Test Readability**: Tests must read like user stories and serve as living documentation

### TDD Implementation Requirements
1. **Red Phase**: Write failing test that describes exact desired behavior
2. **Green Phase**: Write minimal code to make test pass (no over-engineering)
3. **Refactor Phase**: Improve code quality while keeping tests green
4. **Documentation Update**: Update backlog status and implementation log

## Code Quality Standards

### Phoenix/Elixir Specific Standards
- **Authentication**: Always use `@current_scope.user`, never `@current_user`
- **LiveView Memory**: Use `stream()` for collections, avoid large `assign()`
- **Components**: Use built-in `<.input>` and `<.icon>` components
- **Error Handling**: Use tagged tuples `{:ok, result}` / `{:error, reason}`
- **Performance**: LiveView updates <50ms, database queries <100ms

### Code Review Requirements
- **All tests pass**: No exceptions for any code changes
- **Zero warnings**: `mix compile --warnings-as-errors` must pass
- **Code formatting**: `mix format` applied consistently
- **Static analysis**: `mix credo` passes with no issues
- **Security audit**: `mix deps.audit` shows no vulnerabilities

## Documentation Standards

### Required Documentation Updates
**Every feature completion requires:**
1. **Implementation Log Update**: Mark feature as ✅ Complete in `documentation/legacy_implementation_log.md`
2. **Test Coverage Documentation**: Reference specific test files that prove functionality
3. **Progress Percentage Update**: Realistic MVP completion percentage
4. **Backlog Status Update**: Mark backlog items as #status/done

**Architectural Changes Require:**
1. **ADR Creation**: Document significant decisions in `documentation/architectural_decision_records.md`
2. **System Documentation**: Update relevant system architecture documentation
3. **Pattern Documentation**: Update development patterns if new patterns introduced

### Documentation Quality Requirements
- **Accuracy**: Documentation must reflect actual system state, not aspirational state
- **Testability**: All documented procedures must be tested and validated
- **Specificity**: Include concrete examples and exact steps
- **Maintainability**: Keep documentation DRY and reference single sources of truth

## Performance Standards

### Application Performance Targets
- **Page Loads**: <200ms for all user-facing pages
- **API Responses**: <100ms for database queries
- **Real-time Updates**: <50ms for LiveView updates
- **Search Results**: <300ms for restaurant discovery
- **Payment Processing**: <2 seconds end-to-end

### Development Performance Standards
- **Test Suite**: Complete execution in <30 seconds
- **Development Server**: Hot reload <500ms for code changes
- **Build Process**: `mix compile` completes in <10 seconds
- **Database Migrations**: All migrations reversible and <1 second execution

## Business Logic Quality Standards

### EatFair-Specific Business Rules
- **Zero Commission**: All commission calculations must result in 0% for restaurant owners
- **Delivery Accuracy**: All location-based features must be accurate within 100m
- **Price Integrity**: All financial calculations must be accurate to the cent
- **User Experience**: All user flows must be completable without external help

### Data Integrity Requirements
- **Financial Data**: All financial calculations must be auditable and reversible
- **User Data**: All user data changes must be logged and traceable
- **Business Data**: Restaurant and menu data must be version-controlled
- **Location Data**: All address data must be validated and geocoded

## Quality Gates

### Pre-Commit Quality Gates
**All code changes must pass:**
```bash
mix test                              # All tests pass
mix format --check-formatted          # Code is formatted
mix compile --warnings-as-errors      # No compilation warnings
mix credo --strict                    # Static analysis passes
mix deps.audit                       # No security vulnerabilities
```

### Feature Completion Quality Gates
**Before marking any feature as complete:**
1. **End-to-end test exists** and passes for complete user journey
2. **Manual testing completed** with realistic data scenarios
3. **Performance validated** meets target response times
4. **Error handling tested** for all failure scenarios
5. **Documentation updated** reflects new functionality
6. **Backlog status updated** with accurate progress

### Production Readiness Quality Gates
**Before any production deployment:**
1. **All tests pass** in production-like environment
2. **Performance validated** under realistic load
3. **Security review completed** for all changes
4. **Rollback plan documented** and tested
5. **Monitoring configured** for new functionality

This configuration applies to all quality-related prompts including #test_author, #code_review, #run_all_tests, and #feature_dev.
