# Account Setup Flow Overhaul

**Status**: #status/in_progress  
**Priority**: High  
**Estimated Effort**: 3-4 days  
**Dependencies**: None  
**Created**: 2025-08-30T12:25:11Z

## User Story

**As a user completing my account setup after email verification**  
**I want a streamlined, secure, and intuitive flow**  
**So that I can quickly confirm my account details and start using the platform**

## Problem Statement

Based on comprehensive user testing feedback, the current account setup flow has multiple critical UX and security issues:

1. **Legal Compliance Issues**: Terms and conditions acceptance is not enforced
2. **Security Vulnerabilities**: Users can modify their verified email address
3. **Poor UX**: Form is too vertically spread and confusing with dual-path presentation
4. **Address Parsing Issues**: Smart address distribution doesn't work properly
5. **Missing Integrations**: Account setup is disconnected from order journey
6. **Email Flow Issues**: Missing notifications and tracking links in wrong places

## Detailed Requirements

### **🔒 Security & Legal Compliance**

#### Terms and Conditions Enforcement
- **MUST**: Terms acceptance checkbox is required (client & server validation)
- **MUST**: Create audit table `terms_acceptances` (user_id, accepted_at, version, ip_address)
- **MUST**: Store one record per acceptance, never update (insert-only)
- **SHOULD**: Include terms version for future changes

#### Email Security
- **MUST**: Display email as immutable (read-only) field with security context
- **MUST**: Prevent email modification through form submission (server-side protection)
- **SHOULD**: Show clear messaging that email is verified and unchangeable

### **📋 UX & Interface Improvements**

#### Vertical Compression
- **MUST**: Make form more vertically compact for easier completion
- **SHOULD**: Reduce spacing between sections
- **SHOULD**: Use better typography hierarchy

#### Simplified Flow
- **MUST**: Remove "OR" separator and dual-path confusion
- **MUST**: Remove "Complete without password" button
- **MUST**: Keep password optional but in single unified flow
- **SHOULD**: Update copy to be clearer about both options being valid

#### Smart Pre-filling
- **MUST**: Pre-fill name when available from order data
- **MUST**: Smart address distribution across separate fields (street, postal code, city)
- **SHOULD**: Pre-fill marketing preferences when collected in order flow

### **🏗️ Technical Implementation**

#### Database Schema Changes
```sql
-- New table for legal compliance audit trail
CREATE TABLE terms_acceptances (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  accepted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  terms_version VARCHAR(20) NOT NULL DEFAULT 'v1.0',
  ip_address INET,
  user_agent TEXT,
  inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add marketing preference field to existing notifications table  
ALTER TABLE user_notification_preferences 
ADD COLUMN marketing_opt_in BOOLEAN NOT NULL DEFAULT false;
```

#### Address Parsing Enhancement
- **MUST**: Create `Eatfair.AddressParser` utility module
- **MUST**: Handle Dutch address formats (street + number, postal code, city)
- **MUST**: Provide fallback for unparseable addresses
- **SHOULD**: Support international formats for future expansion

#### Context Updates
```elixir
# Add to Accounts context
def record_terms_acceptance(user, metadata \\ %{})
def get_terms_acceptance_history(user)
def update_marketing_preferences(user, preferences)
```

### **📧 Email & Notification Flow**

#### Email Template Updates
- **MUST**: Remove tracking link from order verification email (only one link allowed)
- **MUST**: Create new "Account Setup Complete" email template
- **SHOULD**: Send account completion email after successful setup
- **SHOULD**: Include account benefits and next steps in completion email

#### Email Content
- Order verification email should focus only on email verification
- Account setup completion email should include:
  - Welcome message with account benefits
  - Order tracking link (if applicable)
  - Platform features overview
  - Support contact information

### **🛒 Order Journey Integration**

#### Delivery Address Stage Enhancement
- **MUST**: Rename "Essential Information" to "Your Details"
- **MUST**: Add name field as required
- **MUST**: Add marketing opt-in checkbox
- **MUST**: Add terms and conditions acceptance
- **SHOULD**: Keep email verification optional during order flow
- **SHOULD**: Support completing account setup later via email link

#### Flow Considerations
- Anonymous orders must still work without account creation
- Account setup via email verification should pre-fill from order data
- Marketing preferences and terms acceptance from order flow should be respected

## Acceptance Criteria

### **Functional Requirements**
- [ ] **CRITICAL**: Terms acceptance is required and audited (database record created)
- [ ] **CRITICAL**: Email field is immutable and displayed as read-only
- [ ] **CRITICAL**: Smart address parsing distributes fields correctly
- [ ] **HIGH**: Form is vertically compact and easy to complete
- [ ] **HIGH**: Single unified flow (no confusing dual paths)
- [ ] **HIGH**: Name and address pre-fill from order data when available
- [ ] **MEDIUM**: Marketing preferences are persisted and respected
- [ ] **MEDIUM**: Account completion email is sent after setup
- [ ] **MEDIUM**: Order journey includes account setup fields

### **Technical Requirements**
- [ ] All existing tests pass
- [ ] New migrations are reversible
- [ ] Security constraints prevent email tampering
- [ ] Address parser handles edge cases
- [ ] Email templates render correctly
- [ ] Performance impact is minimal

### **User Experience Requirements**
- [ ] Form completes in under 60 seconds for typical user
- [ ] Clear visual hierarchy guides user through form
- [ ] Error messages are helpful and actionable
- [ ] Success flow provides clear next steps
- [ ] Mobile experience is fully functional

## Testing Strategy

### **Unit Tests**
- Address parser with various input formats
- Terms acceptance recording and history
- Email immutability constraints
- Marketing preference persistence

### **Integration Tests**
- Complete account setup flow
- Order journey with account fields
- Email verification to account setup
- Error handling and validation

### **End-to-End Tests**
- Full user journey from order to account setup
- Email flows and template rendering
- Legal compliance audit trail
- Security constraint enforcement

## Technical Implementation Plan

### **Phase 1: Database & Security Foundation**
1. Create terms acceptance audit table
2. Add email immutability constraints  
3. Extend user preferences schema
4. Update Accounts context functions

### **Phase 2: Address Parsing & Pre-filling**
1. Implement AddressParser utility
2. Update AccountSetup parsing logic
3. Add comprehensive address parsing tests
4. Integrate with order data pre-filling

### **Phase 3: UI/UX Improvements**
1. Redesign AccountSetup template for vertical compression
2. Remove dual-path confusion
3. Add immutable email display
4. Update form validation and error handling

### **Phase 4: Order Journey Integration**
1. Update order details stage with account fields
2. Ensure anonymous flow compatibility
3. Add order-to-account-setup data flow
4. Update order journey tests

### **Phase 5: Email & Notifications**
1. Update order verification email template
2. Create account setup completion email
3. Implement notification pipeline
4. Add email template tests

### **Phase 6: Testing & Documentation**
1. Update all affected tests
2. Add new test coverage for changed functionality
3. Update documentation and ADRs
4. Run comprehensive test suite

## Related Files

### **Templates & Views**
- `lib/eatfair_web/live/user_live/account_setup.html.heex`
- `lib/eatfair_web/live/user_live/account_setup.ex` 
- `lib/eatfair_web/live/order_live/details.html.heex`
- `lib/eatfair_web/templates/email/order_verification.text.eex`

### **Contexts & Schemas** 
- `lib/eatfair/accounts.ex`
- `lib/eatfair/accounts/user.ex`
- `lib/eatfair/accounts/address.ex`
- `lib/eatfair/notifications/user_preference.ex`

### **Tests**
- `test/eatfair_web/integration/account_setup_flow_test.exs`
- `test/eatfair_web/live/user_live/account_setup_test.exs`
- `test/eatfair_web/integration/order_flow_test.exs`

### **Migrations**
- New migration for terms_acceptances table
- New migration for marketing preferences
- New migration for email immutability constraints

## Risk Assessment

### **High Risk**
- Email immutability constraints may affect existing user flows
- Database migrations need careful rollback planning
- Order journey changes may impact conversion rates

### **Medium Risk**  
- Address parsing may not handle all edge cases
- Template changes may affect email deliverability
- Performance impact of new audit table

### **Low Risk**
- UI changes are mostly cosmetic improvements
- New email templates are additions, not changes
- Test coverage ensures functionality preservation

## Definition of Done

- [ ] All acceptance criteria met
- [ ] All tests passing (existing + new)
- [ ] Database migrations tested and reversible
- [ ] Security constraints verified
- [ ] Documentation updated
- [ ] Code review completed
- [ ] Performance impact assessed
- [ ] User testing feedback addressed
- [ ] Email templates tested across clients
- [ ] Mobile responsiveness verified
- [ ] Accessibility standards maintained

## Success Metrics

### **Immediate**
- Account setup completion rate maintains or improves
- Terms acceptance compliance at 100%
- Email tampering attempts blocked
- Address parsing accuracy >95%

### **Long-term**  
- Reduced user support tickets about account setup
- Improved marketing opt-in rates
- Better legal compliance audit trail
- Enhanced user satisfaction scores

---

**Linked Documentation:**
- [Product Specification - Account Management](../documentation/product_specification.md#account-management)
- [Process Feedback Framework](../prompts/process_feedback.md)
- [System Constitution (WARP)](../WARP.md)
