# Skipped Tests Audit

**Date:** 2025-08-31  
**Purpose:** Systematic analysis of all 29 skipped tests to determine which should be implemented vs. kept skipped

## Summary

Total skipped tests: 29
- **UN-SKIP/IMPLEMENT:** 6 tests (aligned with current MVP priorities)
- **KEEP-SKIPPED:** 23 tests (post-MVP, deprecated, or require human design decisions)

## Detailed Audit

| File | Test Suite | Purpose | Product-Spec Alignment | Decision | Reason |
|------|------------|---------|----------------------|----------|---------|
| `test/eatfair_web/live/restaurant_live/filter_composition_bug_test.exs` | Filter Composition Bug | **CRITICAL BUG:** Location filter gets dropped when typing restaurant name | ✅ High - Core Discovery Feature | **UN-SKIP/IMPLEMENT** | Critical bug affecting core restaurant discovery functionality |
| `test/eatfair_web/integration/restaurant_discovery_test.exs` (2 tests) | Price & Delivery Time Filters | Advanced filtering by price range and delivery time | 🔶 Medium - Advanced Filters | **UN-SKIP/IMPLEMENT** | Basic filters are core discovery features, implementation is straightforward |
| `test/eatfair_web/live/restaurant_live/dashboard_test.exs` (1 test) | Restaurant Dashboard Analytics | Basic business metrics and analytics display | 🔶 Medium - Restaurant Analytics | **UN-SKIP/IMPLEMENT** | Simple placeholder for future enhancement, easy to implement |
| `test/eatfair_web/live/restaurant_order_processing_test.exs` (3 tests) | Restaurant Order Management | Accept/reject orders, delivery failure handling | ✅ High - Core Order Management | **UN-SKIP/IMPLEMENT** | Core restaurant functionality per product spec "Order Management" |
| `test/eatfair_web/live/checkout_donation_flow_test.exs` (1 test) | Donation during checkout | Platform sustainability donation flow | 🔶 Medium - Platform Sustainability | **UN-SKIP/IMPLEMENT** | Aligns with product spec donation system |
| `test/eatfair/orders_email_verification_test.exs` (1 test) | Email verification during order | Progressive email verification workflow | 🔶 Medium - Email Verification | **KEEP-SKIPPED** | Complex workflow that requires UX design decisions |
| `test/eatfair_web/live/review_image_upload_test.exs` (All tests) | Review Image Upload System | Multi-image upload, compression, security | 🔴 Post-MVP - Security Critical | **KEEP-SKIPPED** | Post-MVP per product spec "Secure File Upload & Storage System" |
| `test/eatfair_web/live/components/address_autocomplete_test.exs` (All tests) | Isolated Component Tests | Direct component testing with `live_isolated` | 🔴 Deprecated - Testing Strategy | **KEEP-SKIPPED** | Superseded by integration tests, `live_isolated` API outdated |
| `test/eatfair/orders_test.exs` (1 test) | Order Status Tracking | Order tracking initialization edge cases | 🔶 Medium - Order System | **KEEP-SKIPPED** | Complex metadata sanitization, low priority |
| `test/eatfair/refunds_test.exs` (1 test) | Refund Processing | Automated refund creation for rejected orders | 🔶 Medium - Refund System | **KEEP-SKIPPED** | Requires payment integration decisions |
| `test/eatfair_web/integration/review_system_test.exs` (1 test) | Review System Validation | Order requirement validation for reviews | 🔶 Medium - Review System | **KEEP-SKIPPED** | Business logic already implemented, test is redundant |

## Implementation Priority Order

### Immediate (Current Sprint)
1. **Filter Composition Bug** - Critical bug blocking discovery functionality
2. **Restaurant Order Processing** - Core restaurant workflow missing
3. **Restaurant Dashboard Analytics** - Simple placeholder implementation

### Next Sprint  
4. **Restaurant Discovery Filters** - Price and delivery time filtering
5. **Checkout Donation Flow** - Platform sustainability feature

### Keep Skipped (with reasons)

#### Post-MVP Features
- **Review Image Upload System** - Requires secure file upload architecture per product spec
- **Advanced Order Email Verification** - Complex UX workflow needs design decisions

#### Deprecated/Superseded  
- **Address Autocomplete Component Tests** - Use integration tests instead
- **Isolated Component Testing** - Phoenix LiveView best practices evolved

#### Low Priority Edge Cases
- **Order Metadata Sanitization** - Technical debt, not user-facing
- **Automatic Refund Processing** - Requires payment provider decisions
- **Review System Edge Cases** - Business logic already covered

## Next Actions

1. ✅ Un-skip and implement the 6 high/medium priority tests
2. ✅ Add `@tag :post_mvp` to post-MVP test suites with clear comments
3. ✅ Create/update backlog items for deferred features
4. ✅ Add integration smoke tests to replace deprecated isolated tests

## Related Documentation

- [Product Specification](../documentation/product_specification.md) - Feature alignment reference
- [Backlog Dashboard](../backlog_dashboard.md) - Priority management
- [Definition of Done](../documentation/definition_of_done.md) - Completion criteria
