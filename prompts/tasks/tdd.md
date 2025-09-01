# Test-Driven Development Methodology

**Tags**: #tdd #testing #development  
**Purpose**: Apply Test-Driven Development cycle to ensure robust, well-designed code  
**Configurable**: Yes - Testing frameworks and TDD workflows

## Quick Usage

```
Use #tdd to implement [feature/functionality] following Red-Green-Refactor cycle
```

## Full Prompt

Apply Test-Driven Development methodology:

**1. Red - Write Failing Test**
- Write a failing test that defines the desired behavior
- Make the test as specific and minimal as possible
- Ensure the test fails for the right reason (not due to syntax errors)
- Focus on one specific behavior or requirement at a time

**2. Green - Make Test Pass**
- Write the minimal code necessary to make the test pass
- Don't worry about code quality or optimization at this stage
- Focus solely on making the test pass quickly
- Avoid implementing functionality not covered by the current test

**3. Refactor - Improve Code Quality**
- Improve the code while keeping all tests green
- Remove duplication and improve design
- Ensure code follows project conventions and best practices
- Run tests frequently to ensure no regression

**4. Repeat Cycle**
- Continue with the next failing test for additional behavior
- Build functionality incrementally with each cycle
- Maintain comprehensive test coverage throughout development
- Ensure each commit represents a complete Red-Green-Refactor cycle

**5. Integration and Validation**
- Apply #run_all_tests to ensure all tests pass
- Apply #code_review to validate implementation quality
- Apply #validation to verify requirements are met
- Commit changes with clear, descriptive messages

Use testing frameworks from: prompts/config/tech_stack.md  
Follow TDD workflows from: prompts/config/workflows.md

## Configuration Points

- **Testing Framework**: Project-specific testing tools and assertions
- **Test Organization**: How to structure and organize test files
- **Mocking Strategy**: When and how to use mocks and stubs
- **CI Integration**: How TDD fits into continuous integration pipeline

## Related Prompts

**Prerequisites**: #clarify_requirements - Understand what to test  
**Complements**: #test_author, #write_tests - Create comprehensive tests  
**Follows**: #run_all_tests, #code_review - Validate implementation

## TDD Best Practices

**Test Naming**: Use descriptive names that explain the behavior being tested  
**Test Size**: Keep tests small and focused on single behaviors  
**Test Independence**: Each test should be independent and not rely on others  
**Test Coverage**: Aim for high coverage but focus on meaningful tests
