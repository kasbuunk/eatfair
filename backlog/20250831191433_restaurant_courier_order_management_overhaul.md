# Restaurant Courier Order Management Overhaul

**ID**: 20250831191433
**Completed On**: 
**Tags**: #status/todo #type/feature #topic/orders #priority/critical
**Impact**: Complete overhaul of restaurant order management UI and courier delivery workflow
**Type**: Feature enhancement addressing critical UX issues and missing courier functionality

## Description

This comprehensive overhaul addresses multiple critical issues identified through hands-on testing of the restaurant order management system. The feedback reveals fundamental UX problems and missing courier integration that prevents the completion of the full delivery journey.

## User Feedback Summary

**From manual testing session:**
- Navigation: Missing navbar on `/restaurant/orders` prevents returning to homepage
- Order Overview: Current card-based view too verbose, needs concise table view
- Order Details: Missing dedicated order detail pages
- Historic Orders: Can't see completed order history
- Courier Integration: Missing courier visibility and batch delivery management
- Delivery Staging: Need planning phase for grouping orders into delivery batches
- Role Separation: Need dedicated courier accounts and workflow

## Analysis Using Process Feedback Framework

### 🔴 CRITICAL BUGS (Production Blockers)
1. **Missing Navigation**: No navbar on order tracking page prevents navigation
2. **Missing Historic Orders**: Restaurant owners cannot see completed orders
3. **No Courier Access**: Couriers mentioned in README but cannot login or access system

### 🟡 USER EXPERIENCE ISSUES (High Priority)
1. **Verbose Order Cards**: Current card view too detailed for overview, needs table format
2. **No Order Detail Pages**: Cannot view detailed information for specific orders
3. **Poor Order Status Visibility**: Hard to distinguish between preparation and delivery stages
4. **Missing Courier Coordination**: Restaurant cannot see courier status or plan deliveries

### 🔵 SPECIFICATION GAPS (Feature Development)
1. **Delivery Batch Management**: Need system for grouping orders for efficient delivery
2. **Courier Dashboard**: Couriers need interface to accept/manage delivery batches
3. **Dual Status Tracking**: Separate preparation status from delivery status
4. **Real-time Courier Communication**: Restaurant and courier need live status updates

## Technical Implementation Plan

### Phase 1: Critical Bug Fixes
- [ ] **Add missing navbar to restaurant order pages**
  - Integration test for navigation presence
  - Update `RestaurantOrderManagementLive` template
  - Ensure consistent navigation across all restaurant pages
- [ ] **Historic orders filtering**
  - Extend `Orders.list_restaurant_orders/2` to include completed orders
  - Add "Active" vs "History" tab interface
  - Database query optimization for large order histories

### Phase 2: Order Management UI Overhaul
- [ ] **Convert card view to table view**
  - Create `RestaurantOrderTableComponent`
  - Sortable columns: Order ID, Customer, Status, Time, Actions
  - Preserve existing card HTML as fallback but remove from active render
- [ ] **Individual order detail pages**
  - New `RestaurantOrderShowLive` for `/restaurant/orders/:id`
  - Complete order information with customer contact details
  - Order item breakdown, delivery information, and status timeline
- [ ] **Enhanced status management**
  - Clear visual distinction between preparation and delivery phases
  - Action buttons contextual to current status
  - Real-time status updates via LiveView PubSub

### Phase 3: Courier Role & Authentication
- [ ] **Courier user role implementation**
  - Add `courier` role to authentication system
  - Authorization policies for courier-only resources
  - Migration for user role updates
- [ ] **Seed dedicated courier accounts**
  - Two couriers affiliated with Night Owl Express
  - Names: "Max Speedman" and "Lisa Lightning" (themed for Night Owl)
  - Email format: `max.speedman@courier.nightowl.nl` and `lisa.lightning@courier.nightowl.nl`
  - Update README with courier login credentials

### Phase 4: Delivery Batch Management
- [ ] **DeliveryBatch schema**
  - New table: `delivery_batches` (id, restaurant_id, courier_id, status, eta, created_at)
  - Status enum: `staged`, `scheduled`, `accepted`, `in_transit`, `completed`
  - Association: batch has_many orders through junction table
- [ ] **Restaurant batch creation interface**
  - UI to select multiple "ready" orders for delivery batch
  - Auto-calculate ETA based on delivery locations and traffic
  - Stage batch for courier acceptance
- [ ] **Delivery status separation**
  - Add `delivery_status` column to orders table
  - Preparation status: `pending`, `confirmed`, `preparing`, `ready`
  - Delivery status: `not_ready`, `staged`, `scheduled`, `in_transit`, `delivered`
  - Update tracking logic to handle dual status system

### Phase 5: Courier Dashboard
- [ ] **Courier interface development**
  - `CourierDashboardLive` at `/courier/dashboard`
  - View available delivery batches from affiliated restaurants
  - Accept/decline batch assignments
  - Real-time status updates during delivery
- [ ] **Real-time coordination**
  - PubSub channels for restaurant-courier communication
  - Live status updates: courier location, ETA updates, delivery confirmations
  - Restaurant dashboard shows courier activity

### Phase 6: Integration & Testing
- [ ] **End-to-end delivery workflow tests**
  - Complete journey from order placement to delivery completion
  - Restaurant staging → courier acceptance → delivery → completion
  - Real-time status updates for all parties (customer, restaurant, courier)
- [ ] **Performance optimization**
  - Database indexing for order and batch queries
  - Efficient real-time updates via selective PubSub subscriptions
  - Mobile-optimized courier interface

## Success Criteria

### Functional Requirements
- [ ] Restaurant owners can navigate seamlessly between all pages
- [ ] Order overview shows concise table with quick access to details
- [ ] Historic orders are accessible and searchable
- [ ] Restaurant can stage orders into delivery batches
- [ ] Couriers can log in and see available delivery opportunities
- [ ] Real-time status updates work for all user types
- [ ] Complete delivery journey from preparation to customer delivery

### Technical Requirements  
- [ ] All existing tests continue to pass
- [ ] New functionality has comprehensive test coverage
- [ ] Database schema supports efficient queries for large order volumes
- [ ] Real-time updates perform well under load
- [ ] Mobile-responsive interfaces for courier use

### User Experience Requirements
- [ ] Intuitive navigation with clear context at each step
- [ ] Quick access to essential information (customer contact, delivery details)
- [ ] Clear visual feedback for status changes and actions
- [ ] Consistent design patterns across restaurant and courier interfaces

## Dependencies

**Required Before Starting:**
- Existing order creation and status management must remain functional
- User authentication system ready for role-based extensions
- Phoenix PubSub for real-time communication
- Database supports complex queries for batch operations

**Related Backlog Items:**
- [Order Delivery Tracking Journey](20250829153620_order_delivery_tracking_journey.md) - Customer tracking improvements
- [Courier Interface & Delivery Management](20250827175000_courier_delivery_management.md) - Advanced courier features

## Definition of Done

- [ ] All feedback items from manual testing are addressed
- [ ] Navigation works consistently across all restaurant pages
- [ ] Order management provides both overview and detail views
- [ ] Historic orders are accessible and properly filtered
- [ ] Two named couriers can log in and access delivery management
- [ ] Restaurant can create delivery batches and track courier status
- [ ] Delivery status is separated from preparation status
- [ ] Real-time updates work reliably for all user types
- [ ] All tests pass including new end-to-end workflow tests
- [ ] Code follows Phoenix/Elixir patterns from AGENTS.md
- [ ] Documentation updated in product specification
- [ ] README updated with new test accounts

#status/todo
