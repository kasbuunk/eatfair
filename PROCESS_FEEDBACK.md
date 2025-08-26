# Process Feedback Prompt

*Comprehensive feedback processing prompt for manual testing results, user experience issues, and production improvements. Integrates with EatFair's TDD approach and quality engineering standards.*

---

## 🎯 **PROMPT ACTIVATION**

**One-liner Usage**: 
```
Read, understand and act on the prompt in PROCESS_FEEDBACK.md with the following feedback: [YOUR_SPECIFIC_FEEDBACK]
```

**Full Process Usage**:
```
Use PROCESS_FEEDBACK.md to systematically address the following manual testing feedback: [YOUR_DETAILED_FEEDBACK]
```

---

## 📋 **FEEDBACK PROCESSING FRAMEWORK**

When invoked with feedback, follow this comprehensive analysis and implementation framework:

### **PHASE 1: FEEDBACK ANALYSIS & CATEGORIZATION**

#### 1.1 Feedback Understanding
- **Extract Specific Issues**: Identify concrete problems, bugs, or improvement opportunities
- **User Journey Mapping**: Determine which user journey(s) are affected
- **Severity Assessment**: Categorize as Critical, High, Medium, or Low priority
- **Specification Alignment**: Compare feedback against PROJECT_SPECIFICATION.md requirements

#### 1.2 Issue Categorization
Classify each feedback item into one of these categories:

**🔴 CRITICAL BUGS** (Production Blockers)
- Features that don't work as intended
- User workflows that fail or produce errors
- Security vulnerabilities or data integrity issues
- Specification violations in implemented features

**🟡 USER EXPERIENCE ISSUES** (High Priority)
- Confusing interfaces or unclear user guidance
- Missing feedback or confirmation messages
- Poor error handling or unclear error states
- Accessibility barriers or usability problems

**🟢 ENHANCEMENT OPPORTUNITIES** (Medium Priority)
- Features working correctly but could be improved
- Missing convenience features that would improve workflow
- Performance optimizations or loading improvements
- Visual design or layout improvements

**🔵 SPECIFICATION GAPS** (Feature Development)
- Missing features from PROJECT_SPECIFICATION.md
- New feature requests aligned with platform mission
- Integration opportunities between existing features

### **PHASE 2: TECHNICAL ANALYSIS**

#### 2.1 Root Cause Analysis
For each identified issue:
- **Current Implementation Status**: What exists and how it currently works
- **Expected Behavior**: What should happen according to specification or good UX
- **Technical Root Cause**: Why the gap exists (missing code, logic error, design flaw)
- **Affected Systems**: Which contexts, LiveViews, or components need changes

#### 2.2 Impact Assessment
- **User Impact**: How many users and workflows are affected
- **Development Effort**: Realistic time estimate for resolution
- **Risk Assessment**: Potential side effects of proposed changes
- **Test Coverage**: What tests exist and what additional testing is needed

### **PHASE 3: SOLUTION DESIGN**

#### 3.1 Solution Planning
For each issue, design specific solutions:
- **Minimum Viable Fix**: Simplest solution that resolves the core issue
- **Comprehensive Solution**: Complete resolution with proper error handling
- **Future-Proofing**: How to prevent similar issues in the future

#### 3.2 Technical Implementation Plan
- **Code Changes Required**: Specific files, functions, and modifications needed
- **Database Changes**: Any schema modifications or data migrations
- **Test Updates**: New tests needed and existing tests to modify
- **Documentation Updates**: Changes needed in PROJECT_IMPLEMENTATION.md

### **PHASE 4: PRIORITIZED IMPLEMENTATION**

#### 4.1 Work Prioritization
Order issues by:
1. **Critical Bugs** (Fix immediately)
2. **High-Impact UX Issues** (Significant user value)
3. **Specification Compliance** (Missing critical features)
4. **Quality Improvements** (Polish and optimization)

#### 4.2 Development Execution
For each prioritized item:
- **Create Todo List**: Use `create_todo_list` for multi-step work (3+ steps)
- **Follow TDD Approach**: Write failing test → implement fix → refactor
- **Update Documentation**: Keep PROJECT_IMPLEMENTATION.md current during development
- **Quality Validation**: Use VALIDATE_ALL_TESTS_PASS.md for complex changes

---

## 🔍 **FEEDBACK ANALYSIS TEMPLATES**

### Template A: Critical Bug Processing
```
## CRITICAL BUG ANALYSIS: [Issue Name]

### Issue Description
- **What happens**: [Specific behavior observed]
- **What should happen**: [Expected correct behavior]
- **Affected user journey**: [Consumer/Restaurant/Courier workflow]
- **Reproduction steps**: [How to reproduce the issue]

### Technical Analysis
- **Root cause**: [Why this is happening]
- **Affected code**: [Specific files/functions involved]
- **Data impact**: [Any data corruption or integrity issues]

### Solution Plan
- **Immediate fix**: [Quick resolution approach]
- **Test coverage**: [Tests to add/modify]
- **Prevention**: [How to avoid similar issues]

### Implementation Tasks
- [ ] Write failing test that reproduces the bug
- [ ] Implement minimum fix to resolve issue
- [ ] Add regression tests for edge cases
- [ ] Update PROJECT_IMPLEMENTATION.md
- [ ] Verify no other functionality is affected
```

### Template B: UX Improvement Processing
```
## UX IMPROVEMENT ANALYSIS: [Issue Name]

### User Experience Gap
- **Current experience**: [What users encounter now]
- **Desired experience**: [What users should encounter]
- **User frustration point**: [Where/why users get confused]
- **Impact on user journey**: [How this affects overall workflow]

### Solution Design
- **UI/UX changes**: [Interface improvements needed]
- **User feedback**: [Messages, confirmations, error states]
- **Flow improvements**: [Workflow or navigation changes]

### Implementation Plan
- **Frontend changes**: [LiveView, template, component updates]
- **Backend changes**: [Context, schema, business logic updates]
- **Test coverage**: [User interaction tests to add]

### Success Criteria
- [ ] User can complete task without confusion
- [ ] Clear feedback provided at each step
- [ ] Error states handled gracefully
- [ ] Mobile/accessibility considerations addressed
```

### Template C: Feature Enhancement Processing
```
## FEATURE ENHANCEMENT ANALYSIS: [Feature Name]

### Enhancement Opportunity
- **Current capability**: [What exists now]
- **Proposed enhancement**: [What could be improved]
- **User value**: [How this benefits users]
- **Specification alignment**: [Reference to PROJECT_SPECIFICATION.md]

### Technical Approach
- **New functionality needed**: [Features to develop]
- **Integration points**: [How this connects to existing features]
- **Database changes**: [Schema modifications needed]

### Development Plan
- **Test-first approach**: [Tests to write before implementation]
- **Implementation phases**: [How to break work into increments]
- **Risk mitigation**: [How to avoid breaking existing functionality]

### Quality Standards
- [ ] End-to-end test covers complete user workflow
- [ ] Integration with existing features is seamless
- [ ] Performance impact is minimal
- [ ] Code follows established patterns from AGENTS.md
```

---

## 🚀 **EXECUTION METHODOLOGY**

### Development Workflow Integration

**For Critical Bugs (Immediate Response)**:
1. **Reproduce Issue**: Write test that demonstrates the problem
2. **Implement Fix**: Minimum viable solution to resolve the issue
3. **Verify Resolution**: Ensure fix works and doesn't break other features
4. **Document**: Update PROJECT_IMPLEMENTATION.md immediately

**For UX Improvements (Systematic Approach)**:
1. **User Journey Analysis**: Map current vs. desired user experience
2. **Design Solution**: Plan UI/UX improvements with clear success criteria
3. **Test-First Implementation**: Write tests describing improved experience
4. **Iterative Development**: Implement in small, testable increments

**For Feature Enhancements (Full TDD Cycle)**:
1. **Specification Review**: Ensure alignment with PROJECT_SPECIFICATION.md
2. **End-to-End Test**: Write comprehensive test for complete feature
3. **Implementation**: Build feature to make test pass
4. **Integration**: Connect with existing features and workflows

### Quality Assurance Standards

**All feedback resolution must meet:**
- ✅ **Test Coverage**: New/modified functionality has comprehensive tests
- ✅ **Specification Compliance**: Changes align with PROJECT_SPECIFICATION.md
- ✅ **Code Quality**: Implementation follows patterns in AGENTS.md
- ✅ **Documentation**: PROJECT_IMPLEMENTATION.md updated with changes
- ✅ **Performance**: No degradation in test suite or application performance

### Documentation Requirements

**PROJECT_IMPLEMENTATION.md Updates**:
- Mark resolved issues as ✅ Complete with references to implementing tests
- Update feature status percentages based on actual improvements
- Document any new technical debt or enhancement opportunities
- Update "Current Recommended Work" with next highest priorities

---

## 🎯 **SUCCESS CRITERIA FOR FEEDBACK PROCESSING**

### Process Completion Indicators
- [ ] **All feedback items categorized** and prioritized appropriately
- [ ] **Root cause analysis completed** for each significant issue
- [ ] **Solution plans documented** with specific implementation steps
- [ ] **Work items prioritized** by impact and development effort

### Implementation Success Indicators
- [ ] **Critical bugs resolved** with regression tests preventing reoccurrence
- [ ] **UX improvements implemented** with measurably better user experience
- [ ] **Enhancement features working** with comprehensive test coverage
- [ ] **Documentation updated** reflecting all changes and current status

### Quality Standards Met
- [ ] **All tests passing** after implementing feedback resolution
- [ ] **Test suite performance maintained** (execution time not significantly increased)
- [ ] **Code quality preserved** following established patterns and conventions
- [ ] **Specification compliance maintained** or improved through changes

---

## 🔗 **INTEGRATION WITH EXISTING WORKFLOWS**

### Reference Documents Integration
- **PROJECT_SPECIFICATION.md**: Validate all changes align with platform requirements
- **PROJECT_IMPLEMENTATION.md**: Update implementation status and test coverage
- **AGENTS.md**: Follow Phoenix/Elixir development patterns and conventions
- **VALIDATE_ALL_TESTS_PASS.md**: Use for comprehensive quality analysis of changes
- **DEVELOPMENT_PROMPTS.md**: Reference existing prompt patterns for common development tasks

### Workflow Compatibility
- **Compatible with START_FEATURE_DEVELOPMENT.md**: Can be used for feature-based feedback
- **Integrates with SYNC_DOCUMENTATION.md**: Ensures documentation stays current
- **Supports PRIORITIZE_WORK.md**: Feedback processing feeds into work prioritization
- **Follows DEVELOPMENT_PROMPTS.md patterns**: Uses established prompt structures

### Documentation Chain Maintenance
1. **Feedback Processing**: Use this prompt to analyze and plan improvements
2. **Implementation Work**: Use appropriate development prompts for actual work
3. **Progress Tracking**: Update PROJECT_IMPLEMENTATION.md during development
4. **Quality Validation**: Use VALIDATE_ALL_TESTS_PASS.md for complex changes
5. **Work Planning**: Feed results into PRIORITIZE_WORK.md for next development cycle

---

## 🎪 **EXAMPLE USAGE SCENARIOS**

### Scenario 1: Manual Testing Reveals Critical Bug
**Feedback**: "When I try to add items to cart on mobile, the 'Add to Cart' button doesn't work on some restaurants."

**Processing Approach**:
1. **Analysis**: Critical Bug - Core ordering functionality failing
2. **Investigation**: Test cart functionality across restaurants and devices
3. **Root Cause**: Identify why button works sometimes and not others
4. **Solution**: Fix underlying issue and add comprehensive cart testing
5. **Prevention**: Add mobile-specific cart interaction tests

### Scenario 2: UX Confusion During Testing
**Feedback**: "It's not clear how to edit my delivery address after I've added one. I spent 5 minutes looking for an edit button."

**Processing Approach**:
1. **Analysis**: UX Issue - Address management discoverability problem
2. **Journey Review**: Map current address management user experience
3. **Solution Design**: Improve address list UI with clear edit/delete options
4. **Implementation**: Enhanced address management interface
5. **Testing**: User journey tests for address editing workflow

### Scenario 3: Feature Performance Issues
**Feedback**: "Restaurant search is really slow when I type, and sometimes results are confusing - restaurants show up that don't actually deliver to me."

**Processing Approach**:
1. **Analysis**: Performance + Logic Issue - Search optimization needed
2. **Technical Investigation**: Review search implementation and delivery filtering
3. **Solution Plan**: Optimize search queries and fix delivery radius logic
4. **Implementation**: Improved search performance with proper filtering
5. **Quality**: Performance tests to prevent regression

---

*This prompt integrates seamlessly with EatFair's existing development workflow and documentation system. Use it to systematically process any manual testing feedback, user experience issues, or improvement opportunities discovered through hands-on platform usage.*
