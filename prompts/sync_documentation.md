# Sync Documentation

*The definitive prompt for keeping PROJECT_IMPLEMENTATION.md aligned with actual codebase state and specification requirements.*

---

## 🚀 Quick Sync (One-Liner)

```
Sync PROJECT_IMPLEMENTATION.md to reflect actual implementation status by running tests, analyzing specification compliance, and updating documentation accurately.
```

---

## 📋 Comprehensive Documentation Sync

Use this when you need detailed analysis and updates:

```
Perform comprehensive documentation sync for EatFair project.

SYNC PROCESS:
1. **RUN TEST SUITE**: Execute `mix test --trace` for detailed results
2. **ANALYZE IMPLEMENTATION**: Inventory all working features with test evidence
3. **VALIDATE SPECIFICATION COMPLIANCE**: Compare implementation against PROJECT_SPECIFICATION.md requirements
4. **IDENTIFY GAPS**: Find missing features, broken functionality, and specification violations
5. **UPDATE DOCUMENTATION**: Sync PROJECT_IMPLEMENTATION.md with reality
6. **SET PRIORITIES**: Recommend next development focus

OUTPUT FORMAT:

## 🧪 Test Suite Status
- **Total Tests**: [number] 
- **Passing**: [number] (**[percentage]%**)
- **Failing**: [number] (❌ [details if any])
- **Test Execution Time**: [time]

## ✅ Working Features (Evidence-Based)
For each feature with passing tests:
- **Feature**: [name]
- **Test Coverage**: [specific test file references]
- **Specification Compliance**: ✅ Full / 🟡 Partial / 🔴 Non-compliant
- **Status**: [what actually works vs what's missing]

## 🔍 Specification Compliance Analysis
### ✅ FULLY COMPLIANT
[Features that perfectly match PROJECT_SPECIFICATION.md requirements]

### 🟡 PARTIALLY COMPLIANT
[Features that work but have gaps vs specification]
- **Feature**: [name]
- **What Works**: [current capability]
- **Specification Requirement**: [what spec requires]
- **Gap**: [specific difference]

### 🔴 SPECIFICATION VIOLATIONS
[Features that violate specification requirements]
- **Feature**: [name]  
- **Violation**: [how it contradicts specification]
- **Fix Required**: [what needs to change]

## 📊 Realistic MVP Progress
Based on specification compliance (not just test coverage):
- **Overall Progress**: [percentage]% → [updated percentage]%
- **Critical Gaps**: [blocking issues for MVP completion]
- **Ready for Production**: Yes/No + [reasoning]

## 🎯 Next Development Priorities
1. **[Priority 1]**: [most critical gap/violation to address]
2. **[Priority 2]**: [next important item]  
3. **[Priority 3]**: [subsequent priority]

## 📝 Documentation Updates Applied
- **Status Changes**: [features marked complete/incomplete/in-progress]
- **Progress Adjustments**: [realistic progress percentage updates]
- **Technical Debt**: [specification gaps and violations documented]
- **Test References**: [added/corrected test file references]

CRITICAL REQUIREMENTS:
- Mark features ✅ Complete ONLY if they fully satisfy PROJECT_SPECIFICATION.md
- Mark specification violations as 🟡 Partially Complete or 🔴 Non-Compliant
- Provide test file evidence for all status claims
- Be brutally honest about actual vs claimed completion
- Update PROJECT_IMPLEMENTATION.md immediately based on findings
```

---

## 🎯 When to Use Each Approach

### Use **Quick Sync** When:
- Starting new development session
- After pulling latest changes
- Before using START_FEATURE_DEVELOPMENT.md
- Regular maintenance (weekly)

### Use **Comprehensive Sync** When:
- Major milestone reviews
- Before important meetings
- Documentation seems significantly out of sync
- After major development phases
- Before deployment preparation

---

## 🔧 Integration with Development Workflow

### Before Feature Development:
```bash
# Quick sync to get accurate starting state
echo "Sync PROJECT_IMPLEMENTATION.md to actual implementation status"
```

### After Feature Development:
```bash  
# Comprehensive sync to validate completion
echo "Run comprehensive documentation sync to validate feature completion and update progress"
```

### Weekly Hygiene:
```bash
# Regular maintenance
echo "Quick documentation sync for weekly project health check"
```

---

## 📋 Quality Standards

### Evidence Requirements:
- ✅ **Test-Based Validation**: Only mark complete what passing tests prove
- ✅ **Specification Alignment**: Features must match PROJECT_SPECIFICATION.md exactly  
- ✅ **Realistic Progress**: Under-promise rather than claim false completeness
- ✅ **Technical Debt Transparency**: Document all gaps and shortcuts

### Update Discipline:
- 🚨 **Immediate Updates**: Never delay documentation after development
- 📝 **Complete Context**: Include test references and reasoning
- 🎯 **Clear Next Steps**: Always specify what needs to happen next
- 🏗️ **Technical Debt**: Document all specification deviations

---

*This replaces UPDATE_PROJECT_DOCUMENTATION.md, SYNC_IMPLEMENTATION_DOC.md, ANALYZE_SPECIFICATION_COMPLIANCE.md, and VALIDATE_ALL_TESTS_PASS.md with a single comprehensive approach.*
