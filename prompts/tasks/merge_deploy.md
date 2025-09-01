# Merge and Deploy

**Tags**: #merge_deploy #integration  
**Purpose**: _TBD – Safely integrate code changes and deploy to target environment_  
**Configurable**: Yes - Git workflow, deployment process, quality gates

❗ **Needs fleshing out** - This prompt is referenced by other prompts but needs detailed implementation.

## Quick Usage

```
Use #merge_deploy to integrate and deploy [completed feature/fix]
```

## Full Prompt

_TODO: Define systematic approach to integration and deployment including:_
- Pre-merge quality validation
- Merge strategy and conflict resolution
- Deployment process and rollback procedures
- Post-deployment validation

## Configuration Points

- **Git Workflow**: Branch strategy, merge vs. rebase preferences
- **Quality Gates**: Required checks before merging (tests, reviews, etc.)
- **Deployment Process**: CI/CD pipeline configuration and manual steps
- **Monitoring**: Post-deployment health checks and alerting

## Related Prompts

**Prerequisites**: #run_all_tests, #code_review - Quality validation before merge  
**Complements**: #post_deploy_checks - Validation after deployment  
**Follows**: Usually the final step in development workflows
