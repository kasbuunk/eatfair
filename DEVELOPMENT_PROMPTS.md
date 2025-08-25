# Development Prompts Collection

*This document contains proven prompts for common development tasks that align with EatFair's TDD approach and mission.*

---

## Feature Development Prompts

### Complete Feature Development Cycle
```
I need to implement [FEATURE_NAME] following TDD approach.

CONTEXT:
- Feature specification: [Link to PROJECT_SPECIFICATION.md section]
- User journey: [Which user journey this supports]
- Priority: [MVP Critical/Phase 2/Nice to Have]

REQUIREMENTS:
1. Write end-to-end test first that describes complete user journey
2. Implement minimum viable feature to make test pass
3. Add edge case tests for sad paths
4. Refactor for code quality while keeping tests green
5. **MANDATORY**: Update PROJECT_IMPLEMENTATION.md with progress immediately upon completion

CONSTRAINTS:
- Test must be delightful to read and tell clear user story
- Implementation should be simplest solution that works
- All tests must run in < 1 second each
- Must align with Phoenix LiveView patterns from AGENTS.md
- Run `mix precommit` before completion

SUCCESS CRITERIA:
- Feature works as described in specification
- Test coverage includes happy and sad paths  
- Code follows established patterns
- Documentation is updated
```

### User Journey Test Creation
```
Create a comprehensive end-to-end test for the [USER_JOURNEY] user journey.

JOURNEY DETAILS:
- User type: [Consumer/Restaurant Owner/Courier]
- Starting point: [Where user begins]
- End goal: [What user wants to achieve]
- Key interactions: [Major steps in the journey]

TEST REQUIREMENTS:
- Use Phoenix.LiveViewTest patterns
- Test should read like a user story
- Include both happy path and error cases
- Use `has_element?/2` over raw HTML assertions
- Add unique DOM IDs for all interactive elements
- Test execution time < 5 seconds

SPECIFICATION ALIGNMENT:
Reference specific sections from PROJECT_SPECIFICATION.md that this test validates.

Follow existing test patterns from test/eatfair_web/live/ directory.
```

---

## Code Review Prompts

### Comprehensive Code Review
```
Please review this code change for EatFair project.

REVIEW CRITERIA:
1. **Test Coverage**: Does the change have appropriate test coverage?
2. **Specification Alignment**: Does feature match PROJECT_SPECIFICATION.md?
3. **Code Quality**: Is code simple, readable, and maintainable?
4. **Phoenix Patterns**: Follows guidelines in AGENTS.md?
5. **Performance**: Will this affect application performance?
6. **Security**: Any security implications?

FOCUS AREAS:
- Test readability and coverage
- LiveView best practices
- Ecto query efficiency
- Error handling patterns

PROVIDE:
- Specific actionable feedback
- Code examples for suggested improvements
- References to project guidelines when relevant
```

### Test Quality Assessment
```
Review these tests for quality and effectiveness.

EVALUATION CRITERIA:
- **Readability**: Do tests tell clear user stories?
- **Coverage**: Are both happy and sad paths covered?
- **Speed**: Do tests run quickly (< 1 second each)?
- **Reliability**: Are tests stable and deterministic?
- **Maintainability**: Easy to update when requirements change?

CHECK FOR:
- Use of Phoenix.LiveViewTest best practices
- Element-based assertions over HTML string matching
- Clear test descriptions and organization
- Proper setup/teardown patterns
- Unique DOM IDs in templates for test selectors

PROVIDE SPECIFIC IMPROVEMENTS WITH CODE EXAMPLES.
```

---

## Refactoring Prompts

### Technical Debt Resolution
```
I need to address technical debt: [DEBT_DESCRIPTION]

CURRENT STATE:
- What the current implementation does
- Why shortcuts were taken initially
- How it's limiting current development

REQUIREMENTS:
1. Create test that validates current behavior
2. Refactor implementation while keeping tests green
3. Improve code quality without changing functionality
4. Update ARCHITECTURAL_DECISION_RECORDS.md if architecture changes
5. Ensure no performance regression

CONSTRAINTS:
- All existing tests must continue to pass
- No user-facing behavior changes
- Maintain Phoenix LiveView patterns
- Keep refactoring scope focused

SUCCESS CRITERIA:
- Debt is resolved without breaking existing functionality
- Code is more maintainable/readable
- Technical debt is documented in ADR if pattern should be avoided
```

### Performance Optimization
```
Analyze and improve performance of [FEATURE/COMPONENT].

CURRENT METRICS:
- Page load time: [current time]
- Test suite runtime: [current time]
- Database query performance: [current metrics]

TARGETS:
- Page loads < 200ms
- Individual tests < 1 second
- Database queries < 100ms

APPROACH:
1. Profile current performance
2. Identify bottlenecks
3. Create performance tests to prevent regression
4. Implement optimizations
5. Verify improvements meet targets

CONSTRAINTS:
- Don't sacrifice code readability for minor performance gains
- All existing tests must still pass
- Follow Phoenix performance best practices
- Consider using LiveView streams for collections
```

---

## Debugging Prompts

### Bug Investigation and Fix
```
I have a bug: [BUG_DESCRIPTION]

SYMPTOM:
- What users are experiencing
- When/how it occurs
- Error messages if any

INVESTIGATION APPROACH:
1. Create failing test that reproduces the bug
2. Use test to isolate the root cause
3. Identify minimum fix that resolves the issue
4. Verify fix with test and manual testing
5. Check for similar issues elsewhere in codebase

REQUIREMENTS:
- Fix root cause, not symptoms
- Add regression test to prevent reoccurrence
- Ensure fix doesn't break existing functionality
- Update documentation if bug revealed specification gaps

Follow TDD approach: Red (failing test) → Green (fix) → Refactor (improve)
```

### Integration Issue Resolution
```
Debugging integration issue between [SYSTEM_A] and [SYSTEM_B].

PROBLEM:
- Expected behavior vs actual behavior
- Error messages or failure symptoms
- Context where issue occurs

DEBUGGING STRATEGY:
1. Create minimal test case that reproduces issue
2. Add logging to understand data flow
3. Verify each integration point separately
4. Check configuration and environment differences
5. Test boundary conditions and error cases

FOCUS AREAS:
- Phoenix context boundaries
- LiveView state management
- Ecto associations and preloading
- Authentication scope handling

PROVIDE STEP-BY-STEP DEBUGGING APPROACH.
```

---

## Architecture and Design Prompts

### Context Design
```
Design a new Phoenix context for [BUSINESS_DOMAIN].

REQUIREMENTS:
- Define schemas and relationships needed
- Public API functions the context should expose
- Consider how it integrates with existing contexts
- Plan database migrations
- Design for testability

CONTEXT DOMAIN:
- [Describe business domain and responsibilities]
- [Key entities and their relationships]
- [Main use cases and workflows]

CONSTRAINTS:
- Follow Phoenix context patterns
- Use Ecto best practices
- Align with existing authentication scopes
- Consider future scaling requirements from ADR

DELIVERABLES:
1. Schema definitions with relationships
2. Context module with public API
3. Migration files
4. Test structure for the context
```

### LiveView Design
```
Design LiveView for [USER_INTERACTION].

USER STORY:
- As a [USER_TYPE]
- I want to [GOAL]
- So that [BENEFIT]

REQUIREMENTS:
1. Define LiveView module structure
2. Plan socket state management
3. Design event handling for user interactions
4. Consider real-time updates needed
5. Plan error handling and edge cases

DESIGN CONSIDERATIONS:
- Use LiveView streams for collections
- Follow Phoenix v1.8 patterns
- Integrate with existing authentication scopes
- Consider mobile responsiveness
- Plan for accessibility

DELIVERABLES:
1. LiveView module skeleton
2. Template structure
3. Event handlers
4. Test cases for user interactions
```

---

## Documentation Prompts

### Progress Update
```
Update PROJECT_IMPLEMENTATION.md with completed work.

COMPLETED WORK:
- [List features implemented]
- [Tests added/updated]
- [Technical debt resolved]

UPDATE REQUIREMENTS:
1. **RUN TESTS FIRST**: Execute `mix test --trace` to verify actual status
2. Mark completed user journeys with ✅
3. Update test coverage status
4. Add any new missing features discovered
5. Update overall progress percentage
6. Note any architectural changes or decisions

ENSURE:
- Status icons accurately reflect completion
- Test file references are correct
- Progress tracking is realistic
- Next development priorities are clear

⚠️  CRITICAL: Only mark features complete if tests prove they work!
```

### Documentation Audit and Sync
```
Update PROJECT_IMPLEMENTATION.md to reflect the actual current status of the codebase.

PROCESS:
1. **RUN TESTS**: Execute `mix test --trace` to see which tests are passing/failing
2. **DISCOVER TESTS**: Find all test files and examine what features they cover
3. **ANALYZE IMPLEMENTATION**: Check what contexts, LiveViews, and features actually exist
4. **COMPARE DOCUMENTATION**: Compare actual status with PROJECT_IMPLEMENTATION.md
5. **UPDATE DOCUMENTATION**: Sync the document with reality
6. **IDENTIFY GAPS**: Note any features that exist without tests or vice versa

OUTPUT FORMAT:
## Documentation Audit Results
- **Tests Passing**: [Number/percentage of passing tests]
- **Features Actually Implemented**: [List of working features with test coverage]
- **Documentation Discrepancies**: [What was wrong in the documentation]

## Updated Implementation Status
- **Completed Journeys**: [User journeys that are fully working]
- **Partially Complete**: [What's working vs what's missing]
- **Not Started**: [Features with no implementation]
- **MVP Progress**: [Updated realistic percentage]

REQUIREMENTS:
- Update PROJECT_IMPLEMENTATION.md immediately with accurate status
- Mark completed features as ✅ Complete with test file references
- Update overall MVP progress percentage realistically
- Document any assumptions or technical debt discovered
```

### Specification Compliance Validation
```
Ensure all implemented features comply with PROJECT_SPECIFICATION.md requirements.

VALIDATION PROCESS:
1. **RUN TESTS**: Execute `mix test --trace` to see which tests pass
2. **IDENTIFY IMPLEMENTED FEATURES**: List all features with passing tests
3. **COMPARE WITH SPECIFICATION**: For each implemented feature, compare against PROJECT_SPECIFICATION.md requirements
4. **ASSESS COMPLIANCE**: Determine if implementation matches specification exactly
5. **IDENTIFY GAPS**: Note features that work but violate specification
6. **UPDATE DOCUMENTATION**: Mark non-compliant features appropriately

OUTPUT FORMAT:
## Specification Compliance Report
- **Features Analyzed**: [List of implemented features reviewed]
- **Fully Compliant**: [Features that match specification exactly]
- **Partially Compliant**: [Features that work but have specification gaps]
- **Non-Compliant**: [Features that violate specification requirements]

## Critical Issues Found
For each non-compliant feature:
- **Feature Name**: [Name of feature]
- **Specification Requirement**: [What PROJECT_SPECIFICATION.md says]
- **Current Implementation**: [What actually exists]
- **Compliance Gap**: [How they differ]
- **Fix Required**: [What needs to change]

## Recommendations
- **Immediate Fixes**: [Critical specification violations to address]
- **Technical Debt**: [Minor gaps that can be addressed later]
- **Documentation Updates**: [Changes needed in PROJECT_IMPLEMENTATION.md]

⚠️  CRITICAL: Features that violate specification should be marked as 🟡 Partially Complete or 🔴 Specification Non-Compliant
```

### Architecture Decision Recording
```
Document architectural decision: [DECISION_TITLE]

DECISION CONTEXT:
- Problem being solved
- Available alternatives considered
- Constraints and requirements

ADR STRUCTURE:
1. **Status**: Proposed/Adopted/Superseded
2. **Context**: Background and problem statement
3. **Decision**: What was decided and why
4. **Consequences**: Pros, cons, and mitigations
5. **Implementation Notes**: Technical details

FOLLOW ADR TEMPLATE in ARCHITECTURAL_DECISION_RECORDS.md

ENSURE DECISION ALIGNS WITH:
- Project mission of entrepreneur empowerment
- MVP focus and simplicity principles
- TDD approach and testing philosophy
- Cost-effectiveness for donation-based model
```

---

## Quality Assurance Prompts

### Pre-commit Quality Check
```
Perform comprehensive quality check before commit.

CHECKLIST:
1. **Tests**: All tests pass and new functionality is covered
2. **Formatting**: Code is properly formatted (`mix format`)
3. **Compilation**: No warnings (`mix compile --warnings-as-errors`)
4. **Dependencies**: No unused dependencies (`mix deps.unlock --unused`)
5. **Performance**: Test suite runs in < 30 seconds
6. **Documentation**: Relevant docs are updated

VALIDATION COMMANDS:
- `mix precommit` passes cleanly
- Manual testing of new features works
- No regression in existing functionality

BEFORE COMMITTING:
- **MANDATORY**: Update PROJECT_IMPLEMENTATION.md if feature status changed
- Write clear commit message following convention
- Consider if any ADR updates are needed

⚠️  CRITICAL: If any feature was completed, PROJECT_IMPLEMENTATION.md MUST be updated!
```

### Regression Testing
```
Perform regression testing for [CHANGE_DESCRIPTION].

TESTING SCOPE:
1. **Direct Impact**: Features directly modified
2. **Integration Impact**: Systems that interact with changes
3. **User Journey Impact**: End-to-end flows that include changes
4. **Performance Impact**: Any changes to response times

APPROACH:
1. Run full test suite and verify all pass
2. Manual testing of affected user journeys
3. Performance comparison before/after
4. Cross-browser/device testing if UI changes
5. Database migration testing if schema changes

FOCUS AREAS:
- Authentication flows still work correctly
- LiveView real-time updates function properly
- Form submissions and validations work
- Error handling remains robust

DOCUMENT ANY ISSUES FOUND AND RESOLUTION APPROACH.
```

---

## Emergency Response Prompts

### Production Issue Response
```
PRODUCTION ISSUE: [ISSUE_DESCRIPTION]

IMMEDIATE RESPONSE:
1. **Assess Impact**: How many users affected?
2. **Stabilize**: Can we quickly mitigate damage?
3. **Communicate**: Inform affected users if needed
4. **Document**: Record issue details and timeline

RESOLUTION APPROACH:
1. Create test case that reproduces the issue
2. Identify root cause through systematic debugging
3. Implement minimal fix that resolves issue
4. Deploy fix with monitoring
5. Post-mortem: what can we learn?

PREVENTION:
- What tests could have caught this?
- What monitoring would have alerted us earlier?
- How can we prevent similar issues?

FOLLOW-UP:
- Update test coverage
- Document lessons in DEVELOPMENT_INTERACTION_NOTES.md
- Consider if architectural changes needed
```

---

*Add new prompts to this collection as effective patterns emerge. Each prompt should align with EatFair's mission, TDD approach, and excellence standards.*
