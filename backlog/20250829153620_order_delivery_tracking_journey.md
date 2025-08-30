# Order Delivery Tracking Journey

**Created**: 2025-08-29
**Priority**: High
**Status**: #status/in_progress
**Estimated Effort**: Large (5-7 days)

**CRITICAL BLOCKER RESOLVED**: Fixed Decimal serialization error in notifications that was preventing successful order completion and routing to success page. Users can now complete the full order journey and reach the tracking starting point.

## Overview

Implement comprehensive order delivery tracking system that allows customers to track their order from placement to delivery through a detailed state machine with full audit trail of all status changes.

## User Stories

### Primary User Story - Customer Order Tracking
**As a customer who has placed an order**
**I want to track the real-time status of my delivery**
**So that I know when to expect my food and can see the progress**

**Acceptance Criteria:**
- I can access order tracking via email link in order confirmation
- I can access order tracking via "Track Order" button on order success page
- I can see current order status with clear descriptions
- I can see estimated delivery time when available
- I can see courier location and delivery queue position when in transit
- I receive email notifications for major status changes

### Supporting User Stories

**As a restaurant owner**
**I want to update order statuses efficiently**
**So that customers have accurate delivery information**

**As a courier**
**I want to provide real-time location updates**
**So that customers can track their delivery progress**

## Technical Requirements

### State Machine Definition

The order tracking follows this immutable state progression:

```
order_placed → order_accepted → cooking → ready_for_courier → in_transit → delivered
                    ↓
              order_rejected (terminal state with full refund)
                    ↓
              delivery_failed (terminal state with recovery options)
```

#### State Descriptions

1. **order_placed**
   - Order successfully received and forwarded to restaurant
   - Customer receives order confirmation email with tracking link
   - Default state immediately after order creation

2. **order_accepted** 
   - Restaurant owner has validated and accepted the order
   - Triggers automatic transition to cooking based on delivery timing
   - Customer receives acceptance confirmation email

3. **order_rejected** (Terminal State)
   - Restaurant cannot fulfill order (closed, out of stock, delivery area, etc.)
   - Full payment refunded automatically
   - Restaurant encouraged to provide rejection reason
   - Customer receives rejection email with refund details

4. **cooking**
   - Meals being prepared by restaurant
   - Includes ETA for when food will be ready
   - Automatic transition based on order timing relative to delivery window

5. **ready_for_courier**
   - Meals prepared and packaged, awaiting courier pickup
   - Courier should already be scheduled for pickup by ETA
   - Internal status for logistics coordination

6. **in_transit**
   - Courier has picked up order and is delivering
   - Includes real-time courier location tracking
   - Shows number of deliveries before customer's order
   - Displays estimated delivery time

7. **delivered** (Terminal State)
   - Order successfully delivered to customer
   - Courier confirms delivery with optional feedback
   - Customer receives delivery confirmation email
   - Successful completion of order journey

8. **delivery_failed** (Terminal State)
   - Generic failure state for unrecoverable delivery issues
   - Requires manual intervention and customer contact
   - Flexible recovery options depending on circumstances

### Database Schema Design (Audit Trail Approach)

**Key Principle**: All state changes are INSERT operations, never UPDATE operations. Current state is determined by querying the latest status record.

#### order_status_events table
```sql
CREATE TABLE order_status_events (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(id),
  status VARCHAR(50) NOT NULL,
  occurred_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  actor_id BIGINT REFERENCES users(id), -- who made this change
  actor_type VARCHAR(20) NOT NULL, -- 'customer', 'restaurant', 'courier', 'system'
  metadata JSONB, -- flexible data for each status type
  notes TEXT, -- optional human-readable notes
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  -- Ensure chronological ordering
  CONSTRAINT status_events_order_occurred_at_check CHECK (occurred_at <= created_at)
);

-- Indexes for efficient querying
CREATE INDEX order_status_events_order_id_occurred_at_idx ON order_status_events(order_id, occurred_at DESC);
CREATE INDEX order_status_events_status_occurred_at_idx ON order_status_events(status, occurred_at DESC);
```

#### courier_location_updates table
```sql
CREATE TABLE courier_location_updates (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(id),
  courier_id BIGINT NOT NULL REFERENCES users(id),
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  accuracy_meters INTEGER,
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  delivery_queue_position INTEGER, -- how many deliveries before this one
  estimated_arrival TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for real-time location tracking
CREATE INDEX courier_location_updates_order_id_recorded_at_idx ON courier_location_updates(order_id, recorded_at DESC);
CREATE INDEX courier_location_updates_courier_id_recorded_at_idx ON courier_location_updates(courier_id, recorded_at DESC);
```

#### Metadata Examples by Status

**order_placed metadata:**
```json
{
  "total_amount": 2500,
  "delivery_address_id": 123,
  "requested_delivery_time": "2025-08-29T19:30:00Z"
}
```

**order_accepted metadata:**
```json
{
  "restaurant_user_id": 456,
  "estimated_ready_time": "2025-08-29T19:15:00Z",
  "preparation_time_minutes": 45
}
```

**order_rejected metadata:**
```json
{
  "restaurant_user_id": 456,
  "rejection_reason": "temporarily_closed",
  "rejection_notes": "Kitchen equipment malfunction, unable to prepare orders",
  "refund_amount": 2500,
  "refund_processed_at": "2025-08-29T18:45:00Z"
}
```

**cooking metadata:**
```json
{
  "estimated_ready_time": "2025-08-29T19:15:00Z",
  "preparation_started_at": "2025-08-29T18:30:00Z"
}
```

**in_transit metadata:**
```json
{
  "courier_id": 789,
  "pickup_time": "2025-08-29T19:20:00Z",
  "delivery_queue_position": 2,
  "estimated_delivery_time": "2025-08-29T19:45:00Z"
}
```

**delivered metadata:**
```json
{
  "courier_id": 789,
  "delivery_time": "2025-08-29T19:42:00Z",
  "delivery_notes": "Left at door as requested",
  "customer_satisfaction": "thumbs_up",
  "courier_experience": "smooth_delivery"
}
```

### User Interface Requirements

#### Customer Tracking Page (`/orders/:id/track`)

**Header Section:**
- Order number and restaurant name
- Current status with clear, user-friendly description
- Progress indicator showing completed/current/upcoming steps

**Status-Specific Content:**
- **order_placed**: "Your order is being sent to the restaurant"
- **order_accepted**: "Restaurant is preparing your order" + ETA
- **cooking**: "Your food is being cooked" + preparation ETA  
- **ready_for_courier**: "Your order is ready and waiting for pickup"
- **in_transit**: Live map with courier location + queue position + delivery ETA
- **delivered**: "Your order has been delivered!" + delivery time
- **order_rejected**: Rejection reason + refund information
- **delivery_failed**: Failure details + support contact information

**Interactive Elements:**
- Live updates without page refresh (Phoenix LiveView)
- Map integration for in_transit status
- Email notification preferences
- Support contact options

#### Integration Points

**Order Success Page (`/order/success/:id`):**
- Add prominent "Track Your Order" button
- Link to `/orders/:id/track`

**Order Confirmation Email:**
- Include secure tracking link: `/orders/:id/track?token=:secure_token`
- Tracking link should work for both verified and unverified users

### Technical Implementation Plan

#### Phase 1: Database Schema & Core Logic
- [ ] Create migration for order_status_events table
- [ ] Create migration for courier_location_updates table  
- [ ] Implement OrderStatus context with state transition logic
- [ ] Add order tracking token generation to existing orders
- [ ] Create helper functions for querying current order status

#### Phase 2: LiveView Interface
- [ ] Create OrderTrackingLive LiveView
- [ ] Design order tracking templates with responsive layout
- [ ] Implement real-time status updates via PubSub
- [ ] Add map integration for courier location display

#### Phase 3: Integration & Email Updates
- [x] **RESOLVED**: Fixed notification system Decimal serialization preventing order completion
- [ ] Add "Track Order" button to order success page
- [ ] Update order confirmation email template with tracking link
- [ ] Implement secure token-based tracking access
- [ ] Add email notifications for major status changes

#### Phase 4: Testing & Quality Assurance
- [ ] Unit tests for all state transition logic
- [ ] Integration tests for LiveView functionality
- [ ] End-to-end tests covering complete order tracking journey
- [ ] Performance testing for real-time location updates

### Success Criteria

**Functional Requirements:**
- [ ] Customer can track order status from email link
- [ ] Customer can track order status from success page
- [ ] All status transitions are properly recorded and auditable
- [ ] Real-time updates work without page refresh
- [ ] Map integration shows courier location during transit
- [ ] Email notifications sent for major status changes

**Technical Requirements:**
- [ ] All status changes are immutable (INSERT only)
- [ ] Current status efficiently queryable from audit trail
- [ ] Real-time location updates perform well
- [ ] Secure token-based access without requiring login
- [ ] Full test coverage for all status transitions

**User Experience Requirements:**
- [ ] Clear, non-technical status descriptions
- [ ] Appropriate estimated delivery times
- [ ] Mobile-responsive tracking interface
- [ ] Accessible design following WCAG guidelines

### Future Considerations

**Restaurant Owner Interface (Out of Scope):**
- Multi-order dashboard for restaurant management
- Batch courier assignment and ETA planning
- Order rejection workflow with customer communication

**Courier Interface (Out of Scope):**
- Mobile-optimized delivery management
- Real-time location sharing controls
- Delivery batch planning and navigation

**Advanced Features (Out of Scope):**
- SMS notifications in addition to email
- Push notifications for mobile app
- Advanced analytics and delivery optimization
- Customer feedback collection post-delivery

---

## Dependencies

**Required Before Starting:**
- Existing order creation system must be functional
- User authentication system for secure tracking access
- Email system for notifications and tracking links
- Phoenix PubSub for real-time updates

**Related Backlog Items:**
- Email notification system enhancements
- Mobile responsiveness improvements
- Map integration capabilities

---

## Definition of Done

- [ ] All acceptance criteria met with comprehensive testing
- [ ] Database schema supports audit trail of all status changes
- [ ] Customer tracking interface is fully functional and responsive
- [ ] Email integration works for notifications and tracking links
- [ ] Real-time updates work reliably via LiveView
- [ ] Code follows Phoenix/Elixir patterns from AGENTS.md
- [ ] Documentation updated in PROJECT_IMPLEMENTATION.md
- [ ] All tests pass including end-to-end tracking scenarios

#status/todo
