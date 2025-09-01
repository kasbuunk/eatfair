# Feature Development Orchestration

**Purpose**: Coordinate complete feature development from requirements to deployment

This prompt orchestrates the complete feature development process using the specialized task prompts.

## Full Process

**1. Requirements and Planning**
- Apply #clarify_requirements to understand what needs to be built
- Apply #product_strategy to ensure alignment with business objectives
- Apply #scope_shaping to define appropriate feature boundaries
- Apply #planning to create development plan and timeline

**2. Development Implementation**
- Apply #feature_dev task prompt for core implementation
- Apply #tdd to ensure test-driven development approach
- Apply #coding to follow best practices during implementation
- Apply #test_author to create comprehensive test coverage

**3. Quality Assurance**
- Apply #code_review to validate code quality and standards
- Apply #run_all_tests to ensure all tests pass
- Apply #validation to verify requirements are met
- Apply #security_privacy if security implications exist

**4. Integration and Deployment**
- Apply #merge_deploy to safely integrate changes
- Apply #doc_update to update relevant documentation
- Apply #backlog_update to track completion status
- Monitor post-deployment metrics and feedback

## Handoff Points

- **After Requirements**: Hand off to development team with clear specifications
- **After Implementation**: Hand off to QA for validation and testing
- **After Quality Gates**: Hand off to DevOps for deployment
- **After Deployment**: Hand off to product team for monitoring

## Configuration

This orchestration process can be customized through:
- `prompts/config/workflows.md` - Development process variations
- `prompts/config/quality_standards.md` - Quality gates and criteria
- `prompts/product_specification.md` - Business requirements and context

## Success Criteria

Feature is complete when:
- All acceptance criteria are met and validated
- All quality gates pass successfully
- Feature is deployed and functioning correctly
- Documentation and knowledge transfer complete
