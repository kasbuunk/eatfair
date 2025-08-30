# Git Workflow and Version Control

Tags: #git #universal #workflow

*Universal Git practices for maintaining clean, readable version history and effective collaboration.*

## Git Workflow

### Branch Strategy
- **Main Branch**: Always deployable, all tests passing
- **Feature Branches**: `feature/short-description` for new features  
- **Hotfix Branches**: `hotfix/issue-description` for critical fixes
- **No Direct Main Commits**: All changes via review process

### Commit Message Convention
```
type(scope): description

Examples:
- feat(restaurants): add restaurant discovery search
- fix(orders): resolve cart item quantity update bug  
- test(menu): add comprehensive menu browsing tests
- docs(readme): update development setup instructions
- refactor(auth): simplify user authentication flow
```

#### Commit Types
- **feat**: New features or functionality
- **fix**: Bug fixes and corrections
- **test**: Adding or updating tests
- **docs**: Documentation changes
- **refactor**: Code refactoring without behavior changes
- **style**: Code formatting and style changes
- **chore**: Maintenance tasks and tooling

### Pull Request Process
1. **Create PR**: Against main branch with clear description
2. **Review Checklist**: 
   - All tests passing
   - Feature matches requirements
   - Code follows style guidelines
   - No security vulnerabilities
3. **Merge Strategy**: Squash and merge for clean history

## Atomic Commits

### Principles
- **Single Purpose**: Each commit represents one logical change
- **Complete**: Commits don't break the build or leave work half-done
- **Clear Description**: Commit messages explain what changed and why
- **Self-Contained**: Each commit can be understood in isolation

### Quality Standards
- **Buildable**: Every commit should compile and pass tests
- **Reviewable**: Commits are sized appropriately for review
- **Revertible**: Each commit can be safely reverted if needed
- **Traceable**: Clear connection between commits and features/fixes

## Collaboration Patterns

### Branch Naming
- Use descriptive names that indicate purpose
- Include issue numbers when applicable: `feature/123-user-authentication`
- Keep names concise but clear
- Use hyphens to separate words

### Merge Practices
- **Squash and Merge**: For feature branches to maintain clean main history
- **Merge Commits**: For significant milestone integrations
- **Fast-Forward**: For simple updates without conflicts
- **No Merge Commits**: In feature branches to keep history linear

## Version Control Hygiene

### Before Committing
- **Stage Intentionally**: Only stage files that belong together
- **Review Changes**: Check diff before committing
- **Write Clear Messages**: Explain the change and motivation
- **Test First**: Ensure all tests pass before committing

### Repository Maintenance
- **Regular Cleanup**: Remove merged branches
- **Tag Releases**: Mark significant versions with git tags
- **Ignore Appropriately**: Keep generated files out of version control
- **Security**: Never commit secrets, keys, or sensitive data

## Conflict Resolution

### Merge Conflict Strategy
1. **Understand Changes**: Review both versions of conflicted code
2. **Communicate**: Discuss with other developers if needed
3. **Preserve Intent**: Keep the intended functionality of both changes
4. **Test Resolution**: Verify merged code works correctly
5. **Document**: Add commit message explaining resolution approach

### Prevention Practices
- **Frequent Merging**: Keep feature branches current with main
- **Small Changes**: Smaller commits reduce conflict likelihood  
- **Communication**: Coordinate when working on same areas
- **Clear Ownership**: Establish file/feature ownership patterns

## History Management

### Keeping Clean History
- **Logical Grouping**: Group related changes in single commits
- **Clear Progression**: History tells the story of development
- **Remove Noise**: Don't commit temporary debugging or experimental code
- **Meaningful Messages**: Future developers can understand decisions

### When to Rewrite History
- **Before Pushing**: Local commits can be amended, squashed, or reordered
- **Never After Pushing**: Don't rewrite shared history
- **Feature Branches**: Can be cleaned up before merging
- **Documentation Fixes**: Combine with related commits when possible

---

*Good version control practices make code collaboration effective and project history useful for understanding development decisions.*
