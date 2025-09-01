# Debugging Methodology

**Tags**: #debugging #troubleshooting  
**Purpose**: General debugging approaches and problem-solving techniques  
**Configurable**: Yes - Debugging tools and techniques

## Quick Usage

```
Use #debugging to troubleshoot and debug [system/issue/problem]
```

## Full Prompt

Apply systematic debugging approaches:

**1. Problem Understanding**
- Apply #context_intake to gather complete problem description
- Reproduce the issue consistently
- Document symptoms and error messages
- Identify scope and impact of the problem

**2. Investigation**
- Apply #debug_bug for software-specific debugging
- Use appropriate debugging tools and techniques
- Examine logs, traces, and system state
- Isolate variables and test hypotheses

**3. Root Cause Analysis**
- Apply #isolate_cause to narrow down the problem
- Trace through system behavior step by step
- Identify the underlying cause, not just symptoms
- Document findings and reasoning

**4. Solution and Validation**
- Implement targeted fix for root cause
- Apply #run_all_tests to validate solution
- Test in realistic conditions
- Monitor for regression or side effects

Use debugging tools from: prompts/config/tech_stack.md  
Follow debugging workflows from: prompts/config/workflows.md

## Configuration Points

- **Debugging Tools**: System-specific debugging utilities
- **Monitoring**: How to access system logs and metrics
- **Testing Environment**: How to replicate issues safely

## Related Prompts

**Prerequisites**: #context_intake - Understand the problem  
**Complements**: #debug_bug, #isolate_cause - Specific debugging steps  
**Follows**: #run_all_tests - Validate solution
