# Routing Rules Configuration

This file defines project-specific routing rules for classifying and handling different types of work requests.

❗ **Project teams should customize this file** with their specific routing logic and escalation procedures.

## Priority Framework

TODO: Define how to assess priority and urgency:
- Critical: Production outages, security incidents
- High: User-facing bugs, revenue-impacting issues  
- Medium: Feature requests, non-critical improvements
- Low: Technical debt, documentation updates

## Complexity Thresholds

TODO: Define criteria for routing to different workflows:
- **Simple**: Single-file changes, configuration updates → #quick_fix
- **Medium**: Feature additions, bug fixes → #feature_dev, #debug_bug
- **Complex**: Multi-system changes, architectural work → #refactor, coordination needed

## Escalation Triggers

TODO: Define what types of work require special handling:
- Security vulnerabilities → Immediate escalation + #incident_resp
- Cross-team dependencies → Coordination required
- Compliance/regulatory changes → Legal/business review needed
- Performance critical changes → Architecture review required

## Team-Specific Routing

TODO: Map work types to team capabilities:
- Frontend changes → Frontend team
- Backend API → Backend team  
- Infrastructure → DevOps/SRE team
- Design changes → Design + Frontend collaboration

## Examples

TODO: Add specific examples of how different request types should be routed in your context.
