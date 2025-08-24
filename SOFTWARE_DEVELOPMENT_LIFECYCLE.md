# Development Lifecycle

*This document defines the development practices, workflows, and standards for the EatFair project.*

## Core Development Philosophy

### Test-Driven Development (TDD) - Non-Negotiable
**TDD is the cornerstone of this project.** Every feature follows the Red-Green-Refactor cycle:

1. **🔴 RED**: Write a failing test that describes the desired behavior
2. **🟢 GREEN**: Write the minimal code to make the test pass  
3. **🔵 REFACTOR**: Improve code quality while keeping tests green

#### TDD Benefits for EatFair
- **Confidence**: Every feature is proven to work through tests
- **Documentation**: Tests serve as executable specifications
- **Design**: TDD drives better API design and architecture
- **Regression Prevention**: Comprehensive test suite prevents breaking changes
- **Fast Feedback**: Quick validation of implementation correctness

### Testing Hierarchy & Strategy

#### 1. End-to-End Tests (Primary Focus)
**Purpose**: Validate complete user journeys match PROJECT_SPECIFICATION.md
- **Location**: `test/eatfair_web/live/*_test.exs`
- **Coverage**: Full user interactions from UI to database
- **Speed**: Fast enough for continuous feedback (< 5 seconds per test)
- **Readability**: Delightful to read, tell user stories clearly

#### 2. Integration Tests (Secondary)
**Purpose**: Test interactions between contexts and boundaries
- **Location**: `test/eatfair/*_test.exs`  
- **Coverage**: Context boundaries, external integrations
- **Focus**: Data flow between modules

#### 3. Unit Tests (As Needed)
**Purpose**: Test complex business logic and edge cases
- **Location**: `test/eatfair/*/unit/*_test.exs`
- **Coverage**: Complex algorithms, calculations, validations
- **Principle**: Only when logic is too complex for integration tests

### Quality Standards

#### Test Quality Metrics
- **Readability**: Tests should read like user stories
- **Speed**: Full test suite runs in < 30 seconds
- **Coverage**: 100% of user journeys covered by E2E tests
- **Reliability**: Tests pass consistently, no flakiness
- **Maintainability**: Easy to update when requirements change

#### Code Quality Standards  
- **Simplicity**: Choose simple solutions over clever ones
- **Clarity**: Code should be self-documenting
- **Consistency**: Follow established patterns within the codebase
- **Performance**: Fast enough for great user experience
- **Security**: No security vulnerabilities in implementation

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
