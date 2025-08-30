# EatFair Work Prioritization System

Tags: #prioritization #eatfair #mvp

*Intelligent work prioritization for early-stage MVP development - recognizes project state and balances feature development with quality engineering.*

**Foundation**: This system applies universal work prioritization principles with EatFair-specific context. For foundational concepts, see:
- **MVP Methodology**: [MVP Development](mvp_development.md) for early-stage principles and anti-patterns
- **TDD Approach**: [TDD Principles](tdd_principles.md) for test-driven development cycle
- **Quality Standards**: [Quality Gates](quality_gates.md) for comprehensive quality requirements

---

## 🎯 Master Prioritization Prompt

**Use this as your primary work prioritization command:**

```
Analyze EatFair's current state and recommend the most impactful work to do right now.

CONTEXT ANALYSIS:
1. **Current Implementation Status**: Run tests and analyze PROJECT_IMPLEMENTATION.md
2. **Specification Compliance**: Compare implementation against PROJECT_SPECIFICATION.md  
3. **Technical Health**: Assess code quality, test coverage, and technical debt
4. **User Experience Gaps**: Identify critical UX issues affecting adoption
5. **Project Phase**: We're in early-stage MVP development (nothing in production yet)

PRIORITIZATION FRAMEWORK:
- **MVP-Critical Features** (Block user adoption if missing)
- **Quality Engineering** (Foundation for sustainable growth) 
- **Technical Debt** (Becoming limiting factors)
- **User Experience Polish** (Improving conversion and satisfaction)
- **Documentation/Process** (Enabling faster development)

OUTPUT FORMAT:
## 🔍 Current Project State
- **Implementation Status**: [Based on actual test results]
- **MVP Completion**: [Realistic percentage based on specification compliance]
- **Critical Blockers**: [Issues preventing user adoption]
- **Technical Health**: [Code quality, test coverage, maintainability]

## 🎯 Recommended Work: [WORK_TYPE]
**Priority Level**: Critical/High/Medium/Low
**Impact**: [User experience, technical foundation, development speed]  
**Effort**: [Small: <4h, Medium: 1-2 days, Large: 3+ days]

## 📋 Justification
- **Why Now**: [Why this work should happen before other priorities]
- **User Impact**: [How this affects restaurant owners and consumers] 
- **Technical Impact**: [How this affects development speed and quality]
- **Risk Mitigation**: [What problems this prevents]

## 🚀 Implementation Approach
[Specific TDD approach, architectural decisions, or process improvements]

## 📝 Documentation Plan
**PROJECT_IMPLEMENTATION.md Updates Required**:
- [ ] Update test coverage section with new tests
- [ ] Mark implementation status changes
- [ ] Update progress percentage
- [ ] Set next "Current Recommended Work"
- [ ] Document architectural decisions made

**Backlog Item Creation**:
- **For substantial feature work or comprehensive implementations**, create backlog item in `backlog/YYYYMMDDHHMMSS_descriptive_name.md`
- **Include backlog metadata**: Status, Priority, Estimated Effort, Dependencies
- **Add user story and acceptance criteria** for clear scope
- **Update backlog_dashboard.md** with appropriate priority position
- **Use backlog format when user requests "extensive" or "comprehensive" implementation**

## 📊 Alternative Options Considered
1. **[Alternative 1]**: [Why deprioritized]
2. **[Alternative 2]**: [Why deprioritized]  
3. **[Alternative 3]**: [Why deprioritized]

CONSTRAINTS:
- Recognize we're in early-stage development (no production users yet)
- Prioritize working software over perfect architecture
- Balance feature development with engineering excellence
- SQLite is perfectly adequate for current scale
- Focus on restaurant owner and consumer experience
```

---

## 🔧 Specialized Work Type Prompts

### Development Work 
**One-liner**: `Implement the next highest-priority work item from PROJECT_IMPLEMENTATION.md.`

**Full prompt reference**: [START_FEATURE_DEVELOPMENT.md](START_FEATURE_DEVELOPMENT.md) - Handles all work item types

---

### Quality Engineering
**One-liner**: `Assess and improve code quality, test coverage, and technical foundation.`

**Full prompt**:
```
Focus on engineering excellence and technical foundation improvements.

QUALITY ASSESSMENT:
1. **Test Quality**: Coverage, speed, reliability, readability
2. **Code Quality**: Maintainability, simplicity, consistency  
3. **Technical Debt**: Shortcuts becoming limiting factors
4. **Performance**: Page loads, test suite speed, database queries
5. **Security**: Authentication, authorization, data protection

POTENTIAL IMPROVEMENTS:
- Test suite optimization and reliability
- Code refactoring for maintainability  
- Database query optimization
- Security vulnerability assessment
- Development workflow improvements

APPROACH:
- Create tests for any quality improvements
- Measure before/after metrics
- Document technical debt decisions in ADRs
- Focus on improvements that accelerate development
```

---

### Specification Compliance
**One-liner**: `Ensure implementation fully aligns with PROJECT_SPECIFICATION.md requirements.`

**Full prompt reference**: [VALIDATE_ALL_TESTS_PASS.md](VALIDATE_ALL_TESTS_PASS.md)

**Extended prompt**:
```
Audit implementation against PROJECT_SPECIFICATION.md and fix compliance gaps.

COMPLIANCE AUDIT:
1. **Feature Requirements**: Does implementation match specification exactly?
2. **Business Logic**: Are business rules correctly implemented?
3. **User Experience**: Does UX align with specification vision?
4. **Data Models**: Do schemas support specification requirements?
5. **Integration Points**: Do system boundaries match specification?

CRITICAL ISSUES:
- Features that work but violate specification (like review system)
- Missing core specification requirements (like location-based search)
- Implementation gaps that affect user experience
- Business logic errors that could harm users

FIX STRATEGY:
- Create tests that validate specification requirements
- Refactor implementation to match specification exactly  
- Update documentation to reflect actual compliance
- Document any justified specification deviations
```

---

### User Experience Optimization
**One-liner**: `Improve user experience for restaurant owners and consumers based on usability testing.`

**Full prompt**:
```
Focus on user experience improvements that increase adoption and satisfaction.

UX ANALYSIS AREAS:
1. **Consumer Journey**: Registration, discovery, ordering, tracking
2. **Restaurant Owner Journey**: Onboarding, menu management, order processing
3. **Mobile Experience**: Responsive design, touch interactions
4. **Performance**: Page load times, interaction responsiveness
5. **Error Handling**: Graceful failures, clear recovery paths

IMPROVEMENT TYPES:
- **Interaction Design**: Simplified flows, better feedback
- **Visual Design**: Clear hierarchies, consistent styling  
- **Accessibility**: Screen reader support, keyboard navigation
- **Performance**: Faster loads, smoother interactions
- **Content Strategy**: Clear messaging, helpful guidance

VALIDATION APPROACH:
- User testing with target audience (restaurant owners, consumers)
- Analytics on user behavior patterns
- A/B testing for significant changes
- Accessibility auditing
- Performance benchmarking
```

---

### Technical Debt Resolution
**One-liner**: `Address technical debt that's becoming a limiting factor for development speed.`

**Full prompt**:
```
Resolve technical debt that's slowing development or increasing risk.

DEBT ASSESSMENT:
1. **Code Debt**: Complex code, poor abstractions, duplicated logic
2. **Test Debt**: Flaky tests, slow suites, poor coverage
3. **Architecture Debt**: Tight coupling, poor separation of concerns
4. **Infrastructure Debt**: Local file storage, SQLite limitations
5. **Process Debt**: Manual tasks, poor documentation

PRIORITIZATION CRITERIA:
- **Development Impact**: How much this slows feature development
- **Risk Level**: Likelihood and impact of problems
- **Compounding Effect**: Whether debt creates more debt over time
- **User Impact**: Whether debt affects user experience

RESOLUTION APPROACH:
- Create tests that prove current behavior works
- Refactor incrementally while keeping tests green
- Measure improvement in development speed
- Document architectural decisions in ADRs
- Update development processes and documentation
```

---

### Documentation & Process
**One-liner**: `Improve documentation and development processes to accelerate team productivity.`

**Full prompt**:
```
Enhance documentation and development processes for faster, more reliable delivery.

DOCUMENTATION AREAS:
1. **Technical Documentation**: API docs, architecture guides, setup instructions
2. **Project Documentation**: Keep PROJECT_IMPLEMENTATION.md current
3. **Process Documentation**: Development workflows, quality standards
4. **Decision Documentation**: ADRs, architectural choices
5. **User Documentation**: Feature usage guides

PROCESS IMPROVEMENTS:
- **Development Workflow**: Faster feedback loops, automated checks
- **Testing Strategy**: More reliable, faster test suites
- **Quality Assurance**: Better pre-commit checks, code review
- **Deployment Process**: Automated deployments, environment management
- **Knowledge Management**: Better onboarding, context preservation

IMPLEMENTATION:
- Update documentation based on actual current state
- Automate manual processes where possible
- Create templates and checklists for common tasks
- Measure and optimize development cycle times
```

---

### Debugging & Troubleshooting  
**One-liner**: `Investigate and resolve bugs or technical issues affecting functionality.`

**Full prompt**:
```
Debug and resolve issues affecting application functionality or development workflow.

INVESTIGATION AREAS:
1. **Functional Bugs**: Features not working as specified
2. **Performance Issues**: Slow pages, inefficient queries  
3. **Test Issues**: Flaky tests, test failures
4. **Development Issues**: Setup problems, tool failures
5. **Integration Issues**: Service communication failures

DEBUGGING APPROACH:
- Create minimal reproduction case
- Add logging to understand data flow
- Use systematic elimination to isolate cause
- Fix root cause, not symptoms
- Add regression tests to prevent reoccurrence

ISSUE TYPES:
- **Critical**: Blocking user actions or development
- **Major**: Degrading user experience significantly  
- **Minor**: Small annoyances or edge cases
- **Technical**: Affecting development but not users
```

---

### Performance Analysis
**One-liner**: `Analyze and optimize application performance for better user experience.`

**Full prompt**:
```
Analyze and improve application performance across all dimensions.

PERFORMANCE AREAS:
1. **Page Load Performance**: Initial render, time to interactive
2. **Database Performance**: Query optimization, connection pooling
3. **Test Suite Performance**: Execution speed, parallelization
4. **LiveView Performance**: Real-time updates, memory usage
5. **Asset Performance**: JavaScript bundles, CSS optimization

ANALYSIS APPROACH:
- Benchmark current performance with tools
- Identify bottlenecks through profiling
- Create performance tests to prevent regression
- Implement optimizations incrementally
- Measure improvements objectively

OPTIMIZATION TARGETS:
- **Page Loads**: < 200ms for all pages
- **API Responses**: < 100ms for database queries  
- **Real-time Updates**: < 50ms for LiveView updates
- **Test Suite**: < 30 seconds total runtime
- **Search Results**: < 300ms for restaurant discovery
```

---

### Failure Recovery & Resilience
**One-liner**: `Improve application resilience and failure recovery mechanisms.`

**Full prompt**:
```
Enhance application resilience and graceful failure handling.

RESILIENCE AREAS:
1. **Error Handling**: Graceful degradation, user-friendly errors
2. **Data Integrity**: Validation, constraints, backups
3. **Service Recovery**: Automatic retries, circuit breakers
4. **User Experience**: Clear error messages, recovery paths
5. **Monitoring**: Error tracking, alerting, health checks

FAILURE SCENARIOS:
- **Database Unavailable**: Graceful degradation, user feedback
- **External Service Failures**: Timeout handling, fallbacks
- **Invalid User Input**: Validation, clear error messages
- **Network Issues**: Offline support, retry mechanisms
- **High Load**: Rate limiting, queue management

IMPLEMENTATION:
- Add comprehensive error handling
- Create monitoring and alerting systems
- Test failure scenarios explicitly
- Document recovery procedures
- Design for graceful degradation
```

---

### A/B Testing & Experimentation
**One-liner**: `Design and implement A/B tests for key user experience decisions.`

**Full prompt**:
```
Set up experimentation framework for data-driven UX improvements.

EXPERIMENTATION AREAS:
1. **User Onboarding**: Registration flow, initial setup
2. **Discovery Experience**: Restaurant search, filtering UI
3. **Ordering Flow**: Cart design, checkout process
4. **Restaurant Management**: Dashboard layout, menu tools
5. **Conversion Optimization**: Call-to-action placement, messaging

A/B TEST FRAMEWORK:
- **Feature Flags**: Toggle features for different user groups
- **Analytics Integration**: Track user behavior and outcomes
- **Statistical Validity**: Proper sample sizes, significance testing
- **Gradual Rollout**: Safe deployment of winning variations

TEST DESIGN:
- Clear hypothesis about expected improvement
- Measurable success metrics
- Minimal viable test implementation
- Plan for analyzing and acting on results

NOTE: Given early-stage development, focus on major UX decisions rather than micro-optimizations.
```

---

### User Feedback Integration
**One-liner**: `Gather, analyze, and integrate user feedback into product improvements.`

**Full prompt**:
```
Establish user feedback loops and integrate insights into development priorities.

FEEDBACK CHANNELS:
1. **Direct User Interviews**: Restaurant owners, consumers
2. **Usage Analytics**: Behavior patterns, drop-off points
3. **Support Requests**: Common problems, confusion points
4. **Community Feedback**: Local restaurant owner networks
5. **Beta Testing**: Structured feedback from early adopters

FEEDBACK ANALYSIS:
- **Categorize Issues**: Bugs, feature requests, UX problems
- **Prioritize by Impact**: How many users affected, severity
- **Identify Patterns**: Common themes, systemic issues
- **Validate with Data**: Confirm feedback with usage analytics

INTEGRATION PROCESS:
- Document feedback in structured format
- Update PROJECT_SPECIFICATION.md if needed
- Create feature requests with user stories
- Plan implementation based on user impact
- Close feedback loop by informing users of changes

EARLY STAGE FOCUS:
- Restaurant owner satisfaction and retention
- Consumer adoption and repeat usage
- Core value proposition validation
```

---

## 🎯 Context-Aware Decision Framework

### Early-Stage Development Principles

**Current Reality**: 
- No production users yet
- ~65% MVP completion with excellent test coverage
- SQLite perfectly adequate for scale
- Focus should be on working software, not premature optimization

**Prioritization Rules**:
1. **User-facing functionality** > Internal tools
2. **Core business value** > Nice-to-have features  
3. **Working software** > Perfect architecture
4. **Test coverage** > Code elegance
5. **Restaurant owner success** > Platform optimization

### Anti-Patterns to Avoid

**❌ Premature Scaling**:
- Migrating to PostgreSQL (SQLite handles thousands of users)
- Complex caching systems (LiveView handles real-time efficiently)
- Microservices architecture (monolith is perfect for current scale)

**❌ Over-Engineering**:
- Abstract frameworks before patterns are clear
- Complex deployment pipelines (simple Fly.io deployment works)
- Elaborate monitoring systems (basic error tracking sufficient)

**❌ Feature Creep**:
- Advanced meal customization (Post-MVP feature)
- Multi-language support (Focus on single market first)
- Advanced analytics dashboards (Basic metrics sufficient)

### ✅ Smart Early-Stage Choices

**Feature Development**:
- Complete core user journeys (order tracking, restaurant discovery)
- Fix specification violations (review system business logic)
- Simple, working solutions over complex perfect ones

**Quality Engineering**:
- Maintain fast test suite (< 30 seconds)
- Keep code readable and maintainable
- Document architectural decisions in ADRs

**User Experience**:
- Focus on restaurant owner delight (they're the key users)
- Ensure consumer experience drives repeat usage
- Mobile-friendly responsive design

---

## 📋 Quick Reference Commands

### Daily Development
```bash
# Quick work prioritization
echo "Prioritize and suggest next work based on current project state"

# Feature development focus
echo "Determine next MVP-critical feature to implement with TDD"

# Quality engineering focus  
echo "Assess and improve code quality, test coverage, and technical foundation"

# Bug fixing focus
echo "Investigate and resolve bugs or technical issues"
```

### Weekly Planning
```bash
# Comprehensive prioritization
echo "Analyze EatFair's current state and recommend the most impactful work"

# Documentation sync
echo "Update PROJECT_IMPLEMENTATION.md to reflect actual tested implementation state"

# Technical debt assessment
echo "Address technical debt that's becoming a limiting factor"
```

### Monthly Reviews
```bash
# Specification compliance audit
echo "Ensure implementation fully aligns with PROJECT_SPECIFICATION.md requirements"

# User experience optimization
echo "Improve user experience based on usability testing and feedback"

# Performance and resilience review
echo "Analyze application performance and failure recovery mechanisms"
```

---

*This prioritization system recognizes that EatFair is in early-stage development and balances feature development with engineering excellence, always prioritizing user value and sustainable growth over premature optimization.*
