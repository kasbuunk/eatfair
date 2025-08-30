# EatFair Development Lifecycle

Tags: #lifecycle #eatfair #workflow

*EatFair-specific development practices, workflows, and standards that implement universal principles for our food platform.*

## Core Development Philosophy

**Foundation**: This project follows universal development principles detailed in:
- **TDD Approach**: See [TDD Principles](tdd_principles.md) for core test-driven development cycle
- **Quality Standards**: See [Quality Gates](quality_gates.md) for comprehensive quality requirements
- **Version Control**: See [Git Workflow](git.md) for version control practices

### EatFair-Specific TDD Implementation

**Testing Hierarchy for Food Platform**:

#### 1. End-to-End Tests (Primary Focus)
**Purpose**: Validate complete user journeys match [Product Specification](../documentation/product_specification.md)
- **Location**: `test/eatfair_web/live/*_test.exs`
- **Coverage**: Restaurant owner, consumer, and courier workflows
- **Speed**: Fast enough for continuous feedback (< 5 seconds per test)
- **Readability**: Tell clear food platform user stories

#### 2. Integration Tests (Secondary)
**Purpose**: Test interactions between EatFair contexts
- **Location**: `test/eatfair/*_test.exs`  
- **Coverage**: Restaurant, Order, User, and Delivery context boundaries
- **Focus**: Data flow between food platform modules

#### 3. Unit Tests (As Needed)
**Purpose**: Test complex EatFair business logic
- **Location**: `test/eatfair/*/unit/*_test.exs`
- **Coverage**: Pricing calculations, delivery algorithms, restaurant matching
- **Principle**: Only when food domain logic is too complex for integration tests

### EatFair Quality Standards

**Inherits from**: [Quality Gates](quality_gates.md) with food platform specifics:
- **User Journey Coverage**: 100% of restaurant discovery, ordering, and delivery flows
- **Performance Targets**: Restaurant search < 300ms, order placement < 200ms
- **Domain Validation**: All food safety and business rules properly tested

## Development Workflow

### Feature Development Cycle

#### 1. Planning Phase
1. **Specification Review**: Ensure feature aligns with PROJECT_SPECIFICATION.md
2. **Test Planning**: Identify required test scenarios (happy/sad paths)
3. **Architecture Review**: Consider impact on existing systems
4. **Estimation**: Time-box feature development

#### 2. Implementation Phase (TDD Cycle)
1. **Write E2E Test**: Create failing test for user journey
2. **Implement Feature**: Build minimum viable implementation  
3. **Make Test Pass**: Iterate until test is green
4. **Refactor**: Improve code quality without breaking tests
5. **Add Edge Cases**: Test sad paths and boundary conditions

#### 3. Integration Phase  
1. **Manual Testing**: Verify feature works in browser
2. **Performance Check**: Ensure feature meets speed requirements
3. **Cross-browser Check**: Test in different browsers/devices
4. **Accessibility Review**: Ensure feature is accessible

#### 4. Completion Phase
1. **Run `mix precommit`**: Ensure all quality checks pass
2. **Update Documentation**: Update PROJECT_IMPLEMENTATION.md progress
3. **Commit Changes**: Clear, descriptive commit messages
4. **Deploy to Staging**: Test in staging environment

### Git Workflow

#### Branch Strategy
- **Main Branch**: Always deployable, all tests passing
- **Feature Branches**: `feature/short-description` for new features  
- **Hotfix Branches**: `hotfix/issue-description` for critical fixes
- **No Direct Main Commits**: All changes via pull request review

#### Commit Message Convention
```
type(scope): description

- feat(restaurants): add restaurant discovery search
- fix(orders): resolve cart item quantity update bug  
- test(menu): add comprehensive menu browsing tests
- docs(readme): update development setup instructions
- refactor(auth): simplify user authentication flow
```

#### Pull Request Process
1. **Create PR**: Against main branch with clear description
2. **Review Checklist**: 
   - All tests passing
   - Feature matches specification
   - Code follows style guidelines
   - No security vulnerabilities
3. **Merge Strategy**: Squash and merge for clean history

### Continuous Integration

#### Pre-commit Checks (Required)
```bash
mix precommit  # Runs all required checks:
  - mix compile --warning-as-errors
  - mix deps.unlock --unused  
  - mix format --check-formatted
  - mix test
```

#### Automated Checks
- **Test Suite**: All tests must pass
- **Code Formatting**: Elixir formatter compliance
- **Dependency Management**: No unused dependencies
- **Compilation**: Zero warnings policy
- **Security Scan**: Check for known vulnerabilities

### Development Environment

#### Required Tools
- **Elixir 1.15+**: Core language runtime
- **Phoenix 1.8+**: Web framework  
- **SQLite**: Development database
- **Node.js**: Asset compilation
- **Git**: Version control

#### Development Commands
```bash
# Setup
mix setup                    # Full project setup

# Development  
mix phx.server              # Start development server
iex -S mix phx.server       # Start with Elixir shell

# Testing
mix test                    # Run all tests
mix test --failed          # Run only failed tests  
mix test test/path/to/specific_test.exs

# Quality
mix precommit              # Run all pre-commit checks
mix format                 # Format code
```

### Code Review Standards

#### What to Review
- **Test Coverage**: Does the change have appropriate test coverage?
- **Specification Alignment**: Does the feature match PROJECT_SPECIFICATION.md?
- **Code Quality**: Is the code clear, simple, and maintainable?
- **Performance**: Will this change affect application performance?
- **Security**: Are there any security implications?

#### Review Guidelines
- **Be Constructive**: Focus on improving the code, not criticizing
- **Ask Questions**: Seek understanding before suggesting changes
- **Share Knowledge**: Explain reasoning behind suggestions  
- **Approve Quickly**: Don't block progress for minor style issues

## Performance Standards

### Application Performance
- **Page Load Time**: < 200ms for all pages
- **API Response Time**: < 100ms for database queries
- **Real-time Updates**: < 50ms for LiveView updates
- **Search Results**: < 300ms for restaurant search

### Test Performance  
- **Full Test Suite**: < 30 seconds total runtime
- **Individual Tests**: < 1 second per test
- **Test Feedback Loop**: < 5 seconds from save to result

## Error Handling & Debugging

### Error Response Strategy
- **User-Friendly Messages**: Clear, actionable error messages
- **Graceful Degradation**: Application remains functional during errors
- **Logging**: Comprehensive error logging for debugging
- **Recovery**: Clear paths for users to recover from errors

### Debugging Approach
1. **Reproduce Issue**: Create failing test that demonstrates problem
2. **Isolate Problem**: Narrow down root cause systematically
3. **Fix Root Cause**: Address underlying issue, not symptoms
4. **Verify Fix**: Ensure test passes and no regressions
5. **Document Learning**: Update documentation with lessons learned

---

*This document evolves with the project. All team members are responsible for maintaining and improving these practices based on what we learn during development.*
