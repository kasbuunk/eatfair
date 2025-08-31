# Code Refactoring & Technical Debt Resolution

Tags: #refactoring #tdd #quality #technical-debt #solid

*Systematic approach to improving code quality, resolving technical debt, and preparing for future features while maintaining all existing functionality.*

**Foundation**: This system integrates universal refactoring principles with EatFair-specific quality standards:
- **TDD Methodology**: [TDD Principles](tdd_principles.md) for test-driven refactoring approach
- **Quality Standards**: [Quality Gates](quality_gates.md) for comprehensive quality assurance
- **Phoenix Patterns**: [Phoenix Framework](phoenix.md) for framework-specific refactoring guidance
- **MVP Context**: [MVP Development](mvp_development.md) for appropriate refactoring scope in early-stage projects

---

## 🚀 Quick Usage (One-Liner)

```
Refactor [COMPONENT/MODULE/FEATURE] using #refactoring #tdd #quality principles while maintaining all existing functionality
```

---

## 📋 Comprehensive Refactoring Framework

Use this for systematic code quality improvements and technical debt resolution:

```
Perform comprehensive refactoring to improve code quality and prepare for future features.

REFACTORING PROCESS:
1. **ESTABLISH SAFETY NET**: Create comprehensive tests for current behavior
2. **IDENTIFY IMPROVEMENT TARGETS**: Code quality, architecture, warnings, technical debt
3. **APPLY BOY SCOUT RULE**: Leave code better than you found it
4. **FOLLOW SOLID PRINCIPLES**: Apply appropriate design principles
5. **MAINTAIN FUNCTIONALITY**: All existing tests must continue passing
6. **UPDATE DOCUMENTATION**: Sync changes with technical decision records

OUTPUT FORMAT:

## 🔍 Current State Analysis
**Target**: [Specific component, module, or system being refactored]
- **Current Implementation**: [What exists now]
- **Quality Issues**: [Code smells, warnings, technical debt]
- **Architectural Concerns**: [Coupling, cohesion, separation of concerns]
- **Performance Issues**: [Bottlenecks or inefficiencies]
- **Maintainability Gaps**: [What makes the code hard to extend/modify]

## 🎯 Refactoring Objectives
**Primary Goals** (Choose 1-2, avoid over-refactoring):
- [ ] **Code Quality**: Improve readability, reduce complexity, eliminate duplication
- [ ] **Architecture**: Better separation of concerns, improved abstraction layers
- [ ] **Performance**: Optimize slow operations without premature optimization
- [ ] **Maintainability**: Make code easier to extend and modify
- [ ] **Warning Resolution**: Address compiler warnings and deprecations
- [ ] **Future Feature Preparation**: Adjust structure for upcoming integrations

## 🧪 Safety Net Strategy
### Test-First Refactoring Approach
1. **Characterization Tests**: Create tests that describe current behavior
   ```bash
   # Run existing tests to establish baseline
   mix test --trace
   ```
2. **Test Coverage Validation**: Ensure refactoring target has comprehensive coverage
3. **Edge Case Testing**: Add tests for boundary conditions and error cases
4. **⚠️ CRITICAL**: Only refactor code that has reliable test coverage

### Test Requirements for Refactoring
- [ ] All existing tests pass before refactoring
- [ ] New tests added ONLY if they support the refactoring process
- [ ] No new features added during refactoring (stay focused)
- [ ] Test execution time remains acceptable (< 30 seconds for full suite)

## 🏗️ SOLID Principles Application

### Single Responsibility Principle (SRP)
- **Current**: [How current code violates SRP]
- **Improvement**: [Extract classes/modules with single responsibilities]
- **Impact**: [How this improves maintainability]

### Open-Closed Principle (OCP)
- **Current**: [Areas requiring modification to extend behavior]
- **Improvement**: [Make extension possible without modification]
- **Impact**: [How this enables future features]

### Liskov Substitution Principle (LSP)
- **Current**: [Inheritance or interface violations]  
- **Improvement**: [Ensure substitutability]
- **Impact**: [Improved polymorphism and testing]

### Interface Segregation Principle (ISP)
- **Current**: [Fat interfaces or forced dependencies]
- **Improvement**: [Split interfaces by client needs]
- **Impact**: [Reduced coupling and cleaner dependencies]

### Dependency Inversion Principle (DIP)
- **Current**: [High-level modules depending on low-level modules]
- **Improvement**: [Depend on abstractions, not concretions]
- **Impact**: [Better testability and flexibility]

## 🎯 Boy Scout Rule Implementation
"Always leave the code better than you found it"

### Incremental Improvements
- **Code Cleanup**: Remove dead code, improve variable names, fix formatting
- **Documentation**: Add/update comments and documentation
- **Simplification**: Reduce complexity without changing behavior
- **Pattern Consistency**: Align with established project patterns

### Quality Improvements
- **Phoenix/LiveView Patterns**: Follow [AGENTS.md](../AGENTS.md) technical guidelines
- **Elixir Best Practices**: Apply language-specific improvements
- **Error Handling**: Improve error messages and recovery paths
- **Performance**: Address obvious inefficiencies (avoid premature optimization)

## 🔧 Refactoring Execution Plan

### Phase 1: Preparation (RED → Establish Safety)
1. **Run Full Test Suite**: Verify all tests pass
   ```bash
   mix test
   ```
2. **Create Characterization Tests**: Document current behavior
3. **Identify Refactoring Boundaries**: Scope the changes clearly
4. **Document Current Architecture**: Note current design decisions

### Phase 2: Incremental Improvement (GREEN → Apply Changes)
1. **Small Steps**: Make one improvement at a time
2. **Continuous Testing**: Run tests after each change
3. **Git Commits**: Atomic commits for each logical improvement
4. **Rollback Ready**: Be prepared to revert if tests break

### Phase 3: Validation (REFACTOR → Verify Improvement)
1. **Full Test Suite**: Ensure all tests still pass
2. **Performance Check**: Verify no performance degradation
3. **Code Review**: Self-review for quality improvement
4. **Documentation Update**: Record architectural decisions

## ⚠️ Refactoring Constraints

### Non-Negotiable Requirements
- **Preserve Functionality**: No user-visible behavior changes
- **Maintain Test Coverage**: All existing tests must continue passing
- **Follow TDD**: Apply Red-Green-Refactor cycle for any changes
- **Phoenix Patterns**: Adhere to established [Phoenix Guidelines](phoenix.md)
- **Performance**: No significant performance degradation

### EatFair-Specific Constraints
- **Authentication Scope**: Use `@current_scope.user`, not `@current_user`
- **LiveView Streams**: Prefer streams over assigns for collections
- **Built-in Components**: Use Phoenix `<.input>` and `<.icon>` components
- **Database**: SQLite is adequate for current scale, avoid premature optimization
- **MVP Focus**: Don't over-engineer for scale not yet needed

### Technical Limitations
- **Scope Boundaries**: Don't refactor beyond the identified target area
- **Breaking Changes**: Avoid changes requiring database migrations
- **External Dependencies**: Minimize new package additions
- **Deployment Impact**: Ensure changes don't require infrastructure updates

## ✅ Success Criteria

### Quality Improvements Achieved
- [ ] Code is more readable and maintainable
- [ ] Complexity reduced without losing functionality  
- [ ] SOLID principles better applied
- [ ] Compiler warnings resolved
- [ ] Technical debt documented or eliminated
- [ ] Future features easier to implement

### Technical Validation
- [ ] All tests pass: `mix test`
- [ ] No compilation warnings: `mix compile --warnings-as-errors`
- [ ] Code formatted: `mix format`
- [ ] Quality gates pass: `mix precommit`
- [ ] Performance maintained or improved
- [ ] No regressions in user experience

### Documentation & Process
- [ ] **PROJECT_IMPLEMENTATION.md Updated**: If refactoring impacts feature status
- [ ] **Architectural Decisions**: Significant changes documented in ADRs
- [ ] **Commit Messages**: Clear, descriptive commit messages following convention
- [ ] **Code Comments**: Improved inline documentation where needed

## 🎪 Integration with Development Workflow

### Before Major Refactoring
**Quick Assessment**: Use this one-liner to evaluate refactoring readiness:
```
Assess refactoring opportunities for [COMPONENT] using #refactoring #quality analysis
```

### During Feature Development
**Continuous Improvement**: Apply boy scout rule during feature work:
```
Apply boy scout rule while implementing [FEATURE] using #refactoring principles
```

### Technical Debt Resolution  
**Systematic Cleanup**: Use [Development Prompts](development_prompts.md) → Technical Debt Resolution for detailed workflow

### High-Level Architecture Preparation
**Future Feature Readiness**: Prepare architecture for upcoming features:
```
Refactor [SYSTEM] to prepare for [UPCOMING_FEATURES] using #refactoring #architecture principles
```

## 🚨 Anti-Patterns to Avoid

### Refactoring Anti-Patterns
- **Big Bang Refactoring**: Massive changes in single commit
- **Scope Creep**: Adding features during refactoring
- **Premature Optimization**: Optimizing without performance problems
- **Pattern Cargo Culting**: Applying patterns without understanding
- **Test Deletion**: Removing tests to make refactoring "easier"

### EatFair-Specific Anti-Patterns
- **Over-Engineering**: Complex patterns for simple MVP needs
- **External Dependencies**: Adding packages without justification  
- **Database Premature Optimization**: Complex database patterns before needed
- **Microservice Preparation**: Splitting code for future microservices
- **Enterprise Patterns**: Complex patterns inappropriate for startup stage

## 🔗 Related Workflows

### Technical Debt Resolution
For detailed technical debt analysis and resolution: [Development Prompts](development_prompts.md) → Technical Debt Resolution

### Quality Engineering
For comprehensive quality improvements: [Quality Gates](quality_gates.md)

### Architecture Documentation
For recording architectural decisions: [Architectural Decision Records](../documentation/architectural_decision_records.md)

### Test-Driven Development
For test-first refactoring approach: [TDD Principles](tdd_principles.md)

---

## 🎯 When to Use This Prompt

### Ideal Refactoring Scenarios
- **Warning Resolution**: Compiler warnings or deprecation notices
- **Code Smell Elimination**: Complex methods, duplicated code, poor naming
- **Architecture Preparation**: Preparing for new features or integrations
- **Performance Issues**: Addressing specific bottlenecks
- **Maintainability Problems**: Code that's difficult to extend or debug

### Not Appropriate For
- **New Feature Development**: Use [Start Feature Development](start_feature_development.md)
- **Bug Fixes**: Use [Development Prompts](development_prompts.md) → Bug Investigation
- **Major Architecture Changes**: Requires separate architectural decision process
- **Breaking Changes**: Changes that affect user experience or APIs

---

*⚠️ REMEMBER: Refactoring is about improving code structure without changing functionality. Always maintain the safety net of passing tests and apply changes incrementally.*
