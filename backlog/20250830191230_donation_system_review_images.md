# Donation System & Review Image Uploads

**Created**: 2025-08-30  
**Priority**: High  
**Status**: #status/todo  
**Estimated Effort**: Large (5-7 days)  

## Overview

Implement comprehensive donation system integration during checkout and delivery notifications, plus multi-image upload capability for reviews. This maintains EatFair's zero-commission model sustainability while enhancing user experience through visual review content.

## User Stories

### Primary User Story - Donation During Checkout
**As a customer placing an order**  
**I want to optionally support the platform with a donation**  
**So that I can help maintain EatFair's zero-commission policy while supporting local restaurants**

**Acceptance Criteria:**
- [ ] I can see an optional donation amount selector during checkout
- [ ] The total price updates in real-time to include my donation
- [ ] I can proceed with €0 donation (donation is purely optional)
- [ ] My donation amount is clearly shown in the order confirmation
- [ ] My donation is processed alongside the order payment

### Supporting User Story - Donation-Aware Delivery Notifications
**As a customer who has received my order**  
**I want to receive contextual messaging about supporting the platform**  
**So that I understand how my contribution helps or can make future contributions**

**Acceptance Criteria:**
- [ ] If I donated during checkout, I receive a thank-you message with social sharing options
- [ ] If I didn't donate, I receive a kind request with donation options and platform support information
- [ ] The notification includes ways to support beyond monetary donations (social sharing, reviews)
- [ ] All donation messaging is encouraging and non-pushy

### Primary User Story - Review Image Uploads
**As a customer who has received a delivered order**  
**I want to upload photos with my restaurant review**  
**So that I can share visual experiences and help other customers make informed decisions**

**Acceptance Criteria:**
- [ ] I can upload multiple images (up to 3) when writing a review
- [ ] Images are validated for type (JPEG, PNG, WebP) and size (≤5MB each)
- [ ] Images are automatically compressed for web display
- [ ] I can preview uploaded images before submitting my review
- [ ] Uploaded images display prominently with my review on restaurant pages
- [ ] Image uploads work on both desktop and mobile devices

## Technical Requirements

### Database Schema Changes

#### Orders Table Enhancement
```sql
ALTER TABLE orders ADD COLUMN donation_amount DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE orders ADD COLUMN donation_currency VARCHAR(3) DEFAULT 'EUR';
```

#### Review Images Table
```sql
CREATE TABLE review_images (
  id BIGSERIAL PRIMARY KEY,
  review_id BIGINT NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  image_path VARCHAR(500) NOT NULL,
  position INTEGER NOT NULL DEFAULT 1,
  compressed_path VARCHAR(500),
  file_size INTEGER,
  mime_type VARCHAR(50),
  inserted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  UNIQUE(review_id, position)
);

CREATE INDEX review_images_review_id_position_idx ON review_images(review_id, position);
```

### Implementation Components

#### 1. Donation System Integration
- **Enhanced Checkout Flow**: Extend `EatfairWeb.OrderLive.Payment` with donation selector
- **Payment Processing**: Update `Orders.process_payment/2` to include donation amounts
- **Order Schema**: Add donation fields to `Eatfair.Orders.Order`
- **Price Calculations**: Extend total calculation logic throughout checkout flow

#### 2. Notification System Enhancement
- **Context-Aware Messaging**: Modify `Eatfair.Notifications.notify_order_status_change/4`
- **Donation Detection**: Add helpers to determine donation status and generate appropriate messaging
- **Social Sharing**: Include share URLs for donated customers in notification data
- **Alternative Support**: Provide non-monetary support options for non-donors

#### 3. Review Image Upload System
- **Image Schema**: Create `Eatfair.Reviews.ReviewImage` with associations
- **Upload Processing**: Extend `Eatfair.FileUpload` with image compression
- **Review Form Enhancement**: Add multi-file upload to review submission
- **Display Integration**: Show images in restaurant review sections
- **Security**: Maintain existing file validation and security measures

### Security & Performance Considerations

#### Image Upload Security
- **File Type Validation**: Strict whitelist of image formats
- **Size Limits**: Maximum 5MB per image, 3 images per review
- **Storage Security**: Maintain existing local storage with S3-compatible architecture
- **Compression**: Automatic image compression to reduce storage and bandwidth

#### Payment Security
- **Donation Validation**: Ensure donation amounts are properly validated and sanitized
- **Currency Handling**: Consistent decimal handling using existing Decimal patterns
- **Transaction Integrity**: Maintain existing payment security measures

### Testing Strategy

#### End-to-End Tests (Primary)
1. **Donation Checkout Flow** (`test/eatfair_web/live/checkout_donation_flow_test.exs`)
   - Customer adds donation → total updates → payment succeeds → order persisted with donation
   - Customer skips donation → checkout succeeds with €0 donation
   - Donation amount displayed correctly throughout checkout process

2. **Notification Integration** (`test/eatfair_web/live/delivery_notification_test.exs`)
   - Delivered order with donation → thank-you notification with social sharing
   - Delivered order without donation → support request with donation options
   - All notification messaging is contextually appropriate

3. **Review Image Upload** (`test/eatfair_web/live/review_image_upload_test.exs`)
   - Valid image upload → compression → display in review
   - Invalid file type → validation error
   - File size exceeding limit → validation error
   - Multiple images → correct ordering and display

#### Integration Tests
- Order creation with donation amounts
- Notification system with donation context
- Review creation with associated images
- File upload processing and compression

### Success Criteria

**Functional Requirements:**
- [ ] Optional donation collection during checkout with real-time total updates
- [ ] Donation amounts properly stored and processed with order payments
- [ ] Context-aware delivery notifications based on donation status
- [ ] Multi-image upload capability for reviews with compression and validation
- [ ] Images display correctly in restaurant review sections
- [ ] All functionality works on both desktop and mobile devices

**Technical Requirements:**
- [ ] Database schema supports donation tracking and review images
- [ ] File upload system handles image compression and validation
- [ ] Payment processing includes donation amounts
- [ ] Notification system generates contextual messaging
- [ ] All new functionality has comprehensive test coverage
- [ ] Performance impact is minimal (checkout process ≤ existing speed)

**User Experience Requirements:**
- [ ] Donation flow is optional and non-intrusive
- [ ] Image upload interface is intuitive and provides clear feedback
- [ ] Error messages are clear and actionable
- [ ] All interfaces are accessible and mobile-responsive

## Dependencies

**Required Before Starting:**
- Existing payment system (`Orders.process_payment/2`)
- Notification system (`Eatfair.Notifications`)
- File upload system (`Eatfair.FileUpload`)
- Review system (`Eatfair.Reviews`)

**External Dependencies:**
- Image compression library (`Mogrify` or similar - development dependency)
- Existing Stripe/Mollie payment processing integration

## Definition of Done

- [ ] All acceptance criteria met with comprehensive E2E test coverage
- [ ] Database migrations created and tested
- [ ] Optional donation flow integrated throughout checkout process
- [ ] Donation amounts included in payment processing and order storage
- [ ] Context-aware delivery notifications implemented
- [ ] Multi-image review upload functionality complete with compression
- [ ] All images display correctly in review sections
- [ ] Code follows Phoenix/Elixir patterns from AGENTS.md
- [ ] Documentation updated in PROJECT_IMPLEMENTATION.md
- [ ] Architectural decisions documented in ADRs
- [ ] All tests pass including end-to-end scenarios (< 30 second suite runtime)
- [ ] Zero compilation warnings with `mix precommit`
- [ ] Feature manually tested in browser on desktop and mobile devices

## Implementation Notes

**TDD Approach:**
1. **RED Phase**: Write failing tests for all user journeys
2. **GREEN Phase**: Implement minimal code to make tests pass
3. **REFACTOR Phase**: Improve code quality while maintaining test suite integrity

**Future Considerations:**
- **Cloud Storage Migration**: Image storage architecture supports future S3 migration
- **Advanced Compression**: Foundation for future thumbnail generation and optimization
- **Donation Analytics**: Schema supports future donation tracking and reporting features
- **Social Integration**: Notification system ready for expanded social sharing features

---

## Related Items
- Platform Donation System (existing backlog item - will be superseded by this implementation)
- Review System (implemented - being extended)
- Order Delivery Tracking Journey (implemented - being enhanced)

#status/todo
