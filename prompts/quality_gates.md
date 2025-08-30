# Quality Gates

Tags: #quality #universal #ci

*Universal quality standards and automated checks that ensure code quality across any project.*

## Continuous Integration Standards

### Pre-commit Quality Gates
Every code change must pass these automated checks before commit:

1. **Test Suite**: All tests must pass
2. **Code Formatting**: Code must be properly formatted according to project standards
3. **Compilation**: Zero warnings policy - code must compile cleanly
4. **Dependency Management**: No unused or vulnerable dependencies
5. **Performance**: Test suite runs within reasonable time limits
6. **Documentation**: Relevant documentation updated with changes

### Automated Quality Checks
- **Static Analysis**: Code follows established patterns and conventions
- **Security Scan**: Check for known vulnerabilities and security issues
- **Performance**: No significant performance regressions
- **Coverage**: Maintain or improve test coverage with changes

## Quality Assurance Checklist

### Before Committing Changes
- [ ] **All tests pass**: Complete test suite execution successful
- [ ] **Code formatted**: Automatic formatting applied consistently
- [ ] **Zero warnings**: No compilation warnings or deprecation notices
- [ ] **Dependencies clean**: No unused packages or security vulnerabilities
- [ ] **Performance maintained**: Test suite and application performance acceptable
- [ ] **Documentation updated**: All relevant documentation reflects changes

### Code Review Standards

#### What to Review
- **Test Coverage**: Does the change have appropriate test coverage?
- **Specification Alignment**: Does the feature match project requirements?
- **Code Quality**: Is the code clear, simple, and maintainable?
- **Performance**: Will this change affect application performance?
- **Security**: Are there any security implications?

#### Review Guidelines
- **Be Constructive**: Focus on improving the code, not criticizing
- **Ask Questions**: Seek understanding before suggesting changes
- **Share Knowledge**: Explain reasoning behind suggestions  
- **Approve Quickly**: Don't block progress for minor style issues

## Performance Standards

### Application Performance Targets
- **Page Load Time**: < 200ms for typical pages
- **API Response Time**: < 100ms for database queries
- **Real-time Updates**: < 50ms for live updates
- **Search Results**: < 300ms for search functionality

### Test Performance Standards
- **Full Test Suite**: < 30 seconds total runtime
- **Individual Tests**: < 1 second per test
- **Test Feedback Loop**: < 5 seconds from save to result

## Error Handling Standards

### Quality Error Response
- **User-Friendly Messages**: Clear, actionable error messages for users
- **Graceful Degradation**: Application remains functional during errors
- **Comprehensive Logging**: Detailed logging for debugging without exposing sensitive data
- **Recovery Guidance**: Clear paths for users to recover from error states

### Debugging Quality Standards
1. **Reproducible Issues**: Create failing tests that demonstrate problems
2. **Systematic Investigation**: Use methodical approach to isolate root causes
3. **Root Cause Fixes**: Address underlying issues, not just symptoms
4. **Regression Prevention**: Add tests to prevent similar issues in the future
5. **Documentation**: Record lessons learned for future reference

## Documentation Quality Standards

### Living Documentation Requirements
- **Accuracy**: Documentation must always reflect current system state
- **Completeness**: All features and changes properly documented
- **Clarity**: Documentation is clear, actionable, and specific
- **Timeliness**: Documentation updated concurrently with code changes

### Quality Documentation Triggers
- **Feature Completion**: Update documentation when features are completed
- **Architectural Changes**: Document significant design or architectural decisions
- **Issue Resolution**: Document problem resolution for future reference
- **Process Improvements**: Update workflows and procedures based on learnings

## Emergency Quality Protocols

### Production Issue Response
1. **Immediate Assessment**: Evaluate impact and affected users
2. **Stabilization**: Implement quick fixes to minimize damage
3. **Communication**: Inform stakeholders and affected users appropriately
4. **Root Cause Analysis**: Investigate and document underlying causes
5. **Prevention**: Implement measures to prevent similar issues

### Quality Recovery Process
- **Issue Reproduction**: Create tests that demonstrate the problem
- **Minimal Fix**: Implement smallest change that resolves the core issue
- **Verification**: Ensure fix works without introducing new problems
- **Documentation**: Update relevant documentation and runbooks
- **Process Improvement**: Identify and implement preventive measures

---

*Quality is everyone's responsibility. These standards ensure we deliver reliable, maintainable software that serves users effectively.*
