# EatFair Security Configuration

**Reference**: This file is referenced from WARP.md and AGENTS.md

This file provides security patterns and incident response procedures for EatFair development.

## Security Development Standards

### Secret Management
- **Never commit secrets** to git history (API keys, passwords, tokens)
- **Use environment variables** for all sensitive configuration
- **Add .env files to .gitignore** to prevent accidental commits
- **Log sanitization**: Never log sensitive data, even in error messages
- **Secret scanning**: Use pre-commit hooks to detect potential secrets

### API Key Security
```bash
# Search for potential API key exposures
git log --all -S"AIza" --oneline  # Google Maps API keys
git log --all -S"sk_" --oneline   # Stripe API keys  
grep -r "api.key" . --exclude-dir=.git
```

### Environment Variable Patterns
```elixir
# Secure environment variable loading
defp get_required_env(key) do
  case System.get_env(key) do
    nil -> raise "Required environment variable #{key} is not set"
    "" -> raise "Required environment variable #{key} is empty"
    value -> value
  end
end

# Never log the actual value
def configure_api() do
  api_key = get_required_env("GOOGLE_MAPS_API_KEY")
  Logger.info("Configuring Google Maps API with key: [REDACTED]")
  {:ok, api_key}
end
```

## Security Regression Checklist

### Before Any Commit
- [ ] Run `git diff --cached` to review staged changes
- [ ] Check for hardcoded secrets in diff output
- [ ] Verify no log files are being committed
- [ ] Run pre-commit secret scanning hooks
- [ ] Review error handling to ensure no secret exposure

### Before Deployment
- [ ] All environment variables properly configured
- [ ] No secrets in application logs or error messages  
- [ ] API keys have appropriate scope restrictions
- [ ] Database connection strings use environment variables
- [ ] SSL/TLS properly configured for all external communications

### After Security Changes
- [ ] Test application functionality with new secrets
- [ ] Verify old credentials are revoked/rotated
- [ ] Update documentation with new security procedures
- [ ] Notify team of any credential changes requiring action

## Incident Response Procedures

### Secret Exposure Response
When secrets are accidentally committed:

1. **Immediate Assessment**
   ```bash
   # Search for all occurrences in git history
   git log --all -S"EXPOSED_SECRET" --oneline
   
   # Check current working directory
   grep -r "EXPOSED_SECRET" . --exclude-dir=.git
   ```

2. **Create Repository Backup**
   ```bash
   cp -r project project-backup-$(date +%Y%m%d_%H%M%S)
   ```

3. **Remove from Git History**
   ```bash
   # Using git-filter-repo (recommended)
   git-filter-repo --replace-text <(echo "EXPOSED_SECRET==>***REMOVED***") --force
   
   # Alternative: using BFG Repo-Cleaner
   java -jar bfg.jar --replace-text replacements.txt
   ```

4. **Revoke Compromised Credentials**
   - Immediately revoke/delete the exposed API key or credential
   - Generate new replacement credentials
   - Update environment variables in all environments
   - Test application functionality with new credentials

5. **Repository Cleanup**
   ```bash
   # Force push cleaned history (coordinate with team)
   git push origin --force --all
   git push origin --force --tags
   ```

6. **Team Communication**
   - Notify all team members of the incident
   - Provide instructions for re-cloning repository
   - Update CI/CD pipelines with new credentials
   - Schedule security review meeting

### Security Vulnerability Response
1. **Assess Impact**: Determine scope and severity
2. **Contain**: Limit access to affected systems
3. **Fix**: Apply security patches or configuration changes
4. **Verify**: Test fixes don't break functionality
5. **Document**: Update security procedures and incident log
6. **Monitor**: Watch for related security issues

## Security Testing Patterns

### Pre-Commit Hooks
```bash
#!/bin/sh
# pre-commit hook for secret detection
grep -r "AIza\|sk_\|pk_\|ACCESS_TOKEN" . --exclude-dir=.git && exit 1
grep -r "password.*=" . --include="*.ex*" --exclude-dir=.git && exit 1
exit 0
```

### Security Audit Commands
```bash
# Regular security auditing
mix deps.audit                    # Check for vulnerable dependencies
grep -r "TODO.*security" .        # Find security TODOs  
mix credo --only security         # Run security-focused static analysis
```

### Secure Development Practices
- **Input validation**: Sanitize all user inputs
- **Output encoding**: Encode data for appropriate context (HTML, JSON, SQL)
- **Authentication**: Always verify user permissions before actions
- **Authorization**: Use scope-based access control
- **Logging**: Log security events, never log sensitive data
- **Error handling**: Don't expose system information in error messages

## Phoenix/Elixir Security Patterns

### Authentication Security
```elixir
# Always use current_scope pattern
def secure_action(socket) do
  current_scope = socket.assigns[:current_scope]
  if current_scope && current_scope.user do
    # Authorized user action
    {:ok, socket}
  else
    # Redirect to login
    {:redirect, Routes.user_session_path(socket, :new)}
  end
end
```

### CSRF Protection
- **Always enabled**: Phoenix enables CSRF protection by default
- **API endpoints**: Use proper authentication for JSON APIs
- **Form tokens**: Verify all form submissions include CSRF tokens

### SQL Injection Prevention
```elixir
# Always use parameterized queries
from(u in User, where: u.email == ^email)  # ✅ Safe

# Never string interpolation in queries
"SELECT * FROM users WHERE email = '#{email}'"  # ❌ Dangerous
```

This configuration provides security guidance for all EatFair development work and should be integrated into relevant prompts like #debug_bug, #feature_dev, and #code_review.
