# Customer Support Methodology

**Tags**: #customer_support #support #help  
**Purpose**: Provide effective customer support and issue resolution  
**Configurable**: Yes - Support processes and escalation procedures

## Quick Usage

```
Use #customer_support to handle [customer inquiry/issue/request]
```

## Full Prompt

Provide systematic customer support:

**1. Issue Understanding**
- Apply #context_intake to gather complete issue description
- Understand customer impact and urgency
- Identify customer context and history
- Classify issue type and severity

**2. Initial Response**
- Acknowledge issue receipt promptly
- Set appropriate expectations for resolution time
- Gather any additional needed information
- Provide immediate workarounds if available

**3. Investigation and Resolution**
- Apply #support_triage for issue classification
- Escalate to appropriate technical team if needed
- Apply #debug_bug if technical issue requires debugging
- Test proposed solutions before recommending

**4. Customer Communication**
- Keep customer informed of progress
- Explain solutions in customer-appropriate language
- Verify customer satisfaction with resolution
- Document resolution for future reference

Use support tools from: prompts/config/support_workflows.md  
Follow communication standards from: prompts/config/support_templates.md

## Configuration Points

- **Support Channels**: How customers can reach support
- **Escalation Procedures**: When and how to escalate issues
- **Response Time Standards**: Expected response and resolution times
- **Knowledge Base**: How to access and update support documentation

## Related Prompts

**Prerequisites**: #context_intake - Understand customer issue  
**Complements**: #support_triage - Classify and route issues  
**Follows**: #doc_update - Update support documentation
