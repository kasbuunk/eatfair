# Update Project Documentation

*Use this prompt to sync PROJECT_IMPLEMENTATION.md with actual development progress.*

---

## Quick Documentation Update Prompt

Copy and paste this into any conversation when documentation might be out of sync:

```
Update PROJECT_IMPLEMENTATION.md to reflect the actual current status of the codebase.

PROCESS:
1. **RUN TESTS**: Execute `mix test --trace` to see which tests are passing/failing
2. **DISCOVER TESTS**: Find all test files and examine what features they cover
3. **ANALYZE IMPLEMENTATION**: Check what contexts, LiveViews, and features actually exist
4. **COMPARE WITH SPECIFICATION**: Compare implemented features against PROJECT_SPECIFICATION.md requirements
5. **ASSESS COMPLETENESS**: Determine if implementation matches specification requirements (not just if tests exist)
6. **UPDATE DOCUMENTATION**: Sync the document with reality based on specification compliance
7. **IDENTIFY GAPS**: Note features with incomplete specification alignment

OUTPUT FORMAT:
## Documentation Audit Results
- **Tests Passing**: [Number/percentage of passing tests]
- **Features Actually Implemented**: [List of working features with test coverage]
- **Specification Compliance**: [How well implementation matches PROJECT_SPECIFICATION.md requirements]
- **Documentation Discrepancies**: [What was wrong in the documentation]

## Updated Implementation Status
- **Completed Journeys**: [User journeys that are fully working]
- **Partially Complete**: [What's working vs what's missing]
- **Not Started**: [Features with no implementation]
- **MVP Progress**: [Updated realistic percentage]

## Technical Debt Identified
- **Missing Tests**: [Features that work but lack test coverage]
- **Broken Features**: [Tests failing, features not working]
- **Specification Gaps**: [Features that exist but don't meet specification requirements]
- **Documentation Gaps**: [Missing or outdated documentation]

## Next Priority Recommendations
- **Based on actual status**: [What should be worked on next]
- **Unblocking dependencies**: [What's currently blocking progress]

REQUIREMENTS:
- Update PROJECT_IMPLEMENTATION.md immediately with accurate status
- Mark completed features as ✅ Complete with test file references
- Update overall MVP progress percentage realistically
- Document any assumptions or technical debt discovered
```

---

## When to Use This Prompt

Use this documentation update prompt:
- **After any development session** that might have changed feature status
- **Before starting new features** to ensure accurate current state
- **When test results don't match documented status**
- **During code reviews** to catch documentation drift
- **At milestone points** to verify project progress

## Documentation Discipline Rules

### For Developers:
1. **Test First, Then Update**: Run tests, then update documentation
2. **Immediate Updates**: Don't wait - update PROJECT_IMPLEMENTATION.md right away
3. **Evidence-Based**: Only mark features complete if tests prove they work
4. **Include Test References**: Always reference the test files that prove implementation

### For Project Management:
1. **Trust Tests Over Claims**: Tests passing = feature works
2. **Realistic Progress**: Better to under-promise and over-deliver
3. **Technical Debt Tracking**: Document what's working but incomplete
4. **Dependency Awareness**: Note what's blocking vs what's truly complete

---

## Integration with Development Workflow

This prompt should be used in conjunction with:
- **START_FEATURE_DEVELOPMENT.md**: Before starting new work
- **Feature completion reviews**: After finishing development
- **Sprint planning**: To understand actual current state
- **Deployment preparation**: To verify what's actually ready

---

*Keeping PROJECT_IMPLEMENTATION.md accurate is critical for project success. This document is the single source of truth for what actually works.*
