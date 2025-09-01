# Validation Methodology

**Tags**: #validation #testing #verification  
**Purpose**: Systematically verify that production code is correct and aligns with project specifications  
**Configurable**: Yes - Testing frameworks and validation criteria

## Quick Usage

```
Use #validation to verify that [feature/code/system] meets all requirements and quality standards
```

## Full Prompt

Systematically validate code and systems against requirements:

**1. Requirements Verification**
- Compare implementation against original specifications
- Verify all acceptance criteria are met
- Check that business logic aligns with requirements
- Validate user experience matches design specifications

**2. Functional Testing**
- Apply #run_all_tests to execute comprehensive test suite
- Verify all unit tests pass with expected behavior
- Execute integration tests for system interactions
- Perform end-to-end testing of complete user workflows

**3. Quality Assurance**
- Apply #code_review to ensure code quality standards
- Verify code follows project conventions and best practices
- Check that error handling is comprehensive and appropriate
- Validate performance meets specified requirements

**4. Edge Case Testing**
- Test boundary conditions and edge cases
- Verify error handling for invalid inputs
- Test system behavior under load or stress conditions
- Validate graceful degradation and recovery mechanisms

**5. Compliance and Standards**
- Verify compliance with security requirements
- Check accessibility standards if applicable
- Validate data privacy and protection measures
- Ensure regulatory compliance where required

**6. Documentation Validation**
- Verify documentation accurately reflects implementation
- Check that API documentation matches actual behavior
- Validate user documentation is complete and accurate
- Ensure technical documentation is up to date

Use testing frameworks from: prompts/config/tech_stack.md  
Follow validation workflows from: prompts/config/quality_standards.md

## Configuration Points

- **Testing Framework**: Project-specific testing tools and frameworks
- **Quality Gates**: Minimum criteria that must be met before approval
- **Validation Checklist**: Project-specific validation requirements
- **Performance Criteria**: Specific performance benchmarks and thresholds

## Related Prompts

**Prerequisites**: #test_author - Create comprehensive tests  
**Complements**: #run_all_tests, #code_review - Execute validation steps  
**Follows**: #merge_deploy - Deploy validated changes
