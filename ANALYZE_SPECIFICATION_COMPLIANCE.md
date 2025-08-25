# Analyze Specification Compliance

*Use this prompt to perform comprehensive analysis of implementation vs specification and sync PROJECT_IMPLEMENTATION.md to actual tested state.*

---

## Comprehensive Analysis Prompt

```
Analyze the current implementation status against PROJECT_SPECIFICATION.md requirements and sync PROJECT_IMPLEMENTATION.md to reflect actual tested capabilities.

ANALYSIS PROCESS:
1. **RUN TEST SUITE**: Execute `mix test --trace` to see which tests pass/fail
2. **DISCOVER ALL TESTS**: Find and examine every test file to understand what's actually tested
3. **INVENTORY IMPLEMENTED FEATURES**: List all features with passing tests
4. **SPECIFICATION MAPPING**: For each implemented feature, compare against PROJECT_SPECIFICATION.md requirements
5. **COMPLIANCE ASSESSMENT**: Determine if implementation fully satisfies specification (not just if it works)
6. **IDENTIFY VIOLATIONS**: Find features that work but don't meet specification requirements
7. **UPDATE DOCUMENTATION**: Sync PROJECT_IMPLEMENTATION.md with accurate status

CRITICAL ANALYSIS POINTS:
- Does the feature do EXACTLY what the specification says it should do?
- Are there missing business rules or constraints from the specification?
- Does the data model support the specification requirements?
- Are there features that allow behavior the specification doesn't intend?

OUTPUT FORMAT:
## Test Suite Analysis
- **Total Tests**: [number] 
- **Passing**: [number] (**[percentage]%**)
- **Failing**: [number]
- **Test Execution Time**: [time]

## Implemented Features Inventory
For each feature with passing tests:
- **Feature Name**: [name]
- **Test Coverage**: [test file locations]
- **Implementation Status**: [what actually works]

## Specification Compliance Assessment
### ✅ FULLY COMPLIANT FEATURES
[Features that perfectly match specification requirements]

### 🟡 PARTIALLY COMPLIANT FEATURES  
[Features that work but have specification gaps]
- **Feature**: [name]
- **What Works**: [current implementation]
- **Specification Requirement**: [what spec actually says]
- **Gap**: [how they differ]
- **Impact**: [significance of the gap]

### 🔴 SPECIFICATION VIOLATIONS
[Features that violate specification requirements]
- **Feature**: [name]
- **Specification Says**: [requirement from spec]
- **Implementation Does**: [what actually happens]
- **Violation**: [how it breaks specification]
- **Fix Required**: [what needs to change]

## MVP Progress Recalculation
Based on specification compliance (not just test coverage):
- **Authentication System**: [percentage]% - [status and gaps]
- **Restaurant Management**: [percentage]% - [status and gaps] 
- **Menu System**: [percentage]% - [status and gaps]
- **Ordering System**: [percentage]% - [status and gaps]
- **Discovery System**: [percentage]% - [status and gaps]
- **Other Features**: [percentage]% - [status and gaps]

**REALISTIC OVERALL MVP PROGRESS**: [percentage]%

## Documentation Updates Required
- **Status Changes**: [features needing status updates]
- **New Missing Features**: [gaps discovered in analysis]
- **Technical Debt**: [specification violations to document]
- **Test References**: [test file references to add/correct]

## Next Development Priorities
Based on specification compliance gaps:
1. **[Priority 1]**: [most critical specification violation to fix]
2. **[Priority 2]**: [next most important gap]
3. **[Priority 3]**: [subsequent priority]

REQUIREMENTS:
- Mark features as ✅ Complete ONLY if they fully satisfy specification
- Mark specification violations as 🟡 Partially Complete or 🔴 Specification Non-Compliant  
- Update overall MVP progress percentage based on specification compliance
- Document all technical debt and specification gaps clearly
- Provide evidence (test file references) for all status claims

⚠️  CRITICAL: This analysis must be brutally honest about specification compliance, not just whether tests pass.
```

---

## When to Use This Analysis

Use this comprehensive analysis:
- **Before major development sessions** to understand true current state
- **When documentation seems out of sync** with actual capabilities  
- **During milestone reviews** to validate real progress
- **Before deployment** to ensure specification compliance
- **After discovering potential specification violations**
- **When stakeholders need accurate progress reporting**

## Analysis Principles

### Specification-First Thinking
1. **The specification is the source of truth** for what features should do
2. **Working code ≠ Complete feature** if it doesn't match specification
3. **Test coverage ≠ Feature completeness** if tests don't validate specification requirements
4. **Business logic gaps are critical flaws** even if UI works perfectly

### Evidence-Based Documentation  
1. **Only mark complete what specification analysis proves is complete**
2. **Document all specification gaps transparently**  
3. **Provide test file evidence for all status claims**
4. **Update progress percentages based on specification compliance**

### Honest Progress Tracking
1. **Better to under-promise and over-deliver** than claim false completeness
2. **Technical debt must be documented** for future development planning
3. **Specification violations are bugs** regardless of test coverage
4. **MVP progress based on specification satisfaction** not just code volume

---

## Integration with Development Workflow

This analysis should be run:
- **BEFORE** using START_FEATURE_DEVELOPMENT.md (to ensure accurate starting state)
- **DURING** complex development (to validate specification alignment)
- **AFTER** significant implementation work (to update documentation)
- **REGULARLY** as part of quality assurance process

---

*This analysis ensures PROJECT_IMPLEMENTATION.md reflects actual specification compliance, not just test coverage. Use it to maintain brutal honesty about true feature completeness.*
