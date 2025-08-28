# EatFair Schema Analysis for Admin Dashboard

*Complete analysis of all EatFair schemas for custom admin dashboard implementation*

## 📊 Schema Overview

### Core Business Entities

#### 1. **Eatfair.Accounts.User** (`users`)
**Purpose**: Central user management for all platform participants

**Admin Dashboard Priority**: 🔴 **High** - Core user management

**Fields**:
- `id` (Primary Key)
- `email` (String, unique) - Search/filter field
- `name` (String) - Display field  
- `role` (String) - Critical filter: `customer`, `restaurant_owner`, `courier`, `admin`
- `phone_number` (String)
- `default_address` (String)
- `hashed_password` (String, redacted)
- `confirmed_at` (UTC DateTime) - Account verification status
- `inserted_at`, `updated_at` (UTC DateTime) - Activity tracking

**Relationships**:
- `has_many :addresses` → Address management
- Owner of restaurants (via restaurant.owner_id)
- Customer of orders (via order.customer_id)
- Courier assignments (via order.courier_id)
- Notification recipient (via events and preferences)

**Admin Dashboard Features**:
- User role management and elevation
- Account status and verification tracking
- Activity monitoring and last login
- Address management oversight
- Password reset capabilities (admin-initiated)
- Bulk operations: role changes, account deactivation

---

#### 2. **Eatfair.Restaurants.Restaurant** (`restaurants`)
**Purpose**: Restaurant business profiles and operational settings

**Admin Dashboard Priority**: 🔴 **High** - Business ecosystem management

**Fields**:
- `id` (Primary Key)
- `name` (String) - Primary display field
- `address` (String) - Location display
- `description` (String) - Business description
- `owner_id` (Foreign Key → User) - Ownership tracking
- `avg_preparation_time` (Integer, minutes) - Operational metrics
- `delivery_radius_km` (Integer) - Service area
- `delivery_time_per_km` (Integer, minutes) - Delivery logistics
- `min_order_value` (Decimal) - Business rules
- `is_open` (Boolean) - Real-time operational status
- `rating` (Decimal) - Community feedback aggregation
- `image_url` (String) - Visual branding
- `cuisine_types` (Array of Strings) - Categorization
- **Geographic Fields**: `latitude`, `longitude`, `city`, `postal_code`, `country` - Location services

**Relationships**:
- `belongs_to :owner, User` - Business ownership
- `many_to_many :cuisines, Cuisine` - Categorization system
- `has_many :menus, Menu` - Menu management
- Target of orders (via order.restaurant_id)

**Admin Dashboard Features**:
- Restaurant approval and verification workflow
- Operational metrics dashboard
- Geographic coverage analysis
- Owner relationship management
- Performance analytics (ratings, orders, revenue)
- Business rules configuration
- Image and branding oversight

---

#### 3. **Eatfair.Orders.Order** (`orders`)
**Purpose**: Order lifecycle and transaction management

**Admin Dashboard Priority**: 🔴 **High** - Transaction oversight and support

**Fields**:
- `id` (Primary Key)
- `customer_id` (Foreign Key → User) - Customer tracking
- `restaurant_id` (Foreign Key → Restaurant) - Business tracking
- `courier_id` (Foreign Key → User, nullable) - Delivery assignment
- `status` (String) - Workflow state: `pending`, `confirmed`, `preparing`, `ready`, `out_for_delivery`, `delivered`, `cancelled`
- `total_price` (Decimal) - Transaction value
- `delivery_address` (String) - Fulfillment location
- `delivery_notes` (String) - Special instructions
- **Status Timestamps**: `confirmed_at`, `preparing_at`, `ready_at`, `out_for_delivery_at`, `delivered_at`, `cancelled_at`
- **Tracking Fields**: `estimated_delivery_at`, `estimated_prep_time_minutes`, `actual_prep_time_minutes`
- **Issue Management**: `is_delayed` (Boolean), `delay_reason` (String), `special_instructions` (String)

**Relationships**:
- `belongs_to :customer, User` - Customer relationship
- `belongs_to :restaurant, Restaurant` - Business relationship
- `belongs_to :courier, User` - Delivery relationship
- `has_many :order_items, OrderItem` - Order composition
- `has_one :payment, Payment` - Transaction tracking

**Admin Dashboard Features**:
- Order status tracking and intervention
- Real-time order flow monitoring
- Customer support tools (status updates, refunds)
- Delivery logistics oversight
- Business intelligence (order volumes, values, patterns)
- Issue resolution workflow
- Performance analytics (prep times, delivery times)

---

### Supporting Entities

#### 4. **Eatfair.Accounts.Address** (`addresses`)
**Purpose**: User delivery address management

**Admin Dashboard Priority**: 🟡 **Medium** - User experience support

**Fields**:
- `id` (Primary Key)
- `user_id` (Foreign Key → User) - Ownership
- `name` (String) - User-friendly label ("Home", "Work")
- `street_address` (String) - Physical location
- `city`, `postal_code`, `country` (Strings) - Geographic data
- `latitude`, `longitude` (Decimal) - Geocoded location
- `is_default` (Boolean) - User preference

**Admin Use Cases**:
- Address validation and geocoding verification
- Geographic coverage analysis
- User experience troubleshooting
- Delivery zone optimization

---

#### 5. **Eatfair.Orders.OrderItem** (`order_items`)
**Purpose**: Individual items within orders

**Admin Dashboard Priority**: 🟡 **Medium** - Order composition analysis

**Fields**:
- `id` (Primary Key)
- `order_id` (Foreign Key → Order) - Order composition
- `meal_id` (Foreign Key → Meal) - Menu item reference
- `quantity` (Integer) - Item count
- `customization_options` (Array of Integers) - Future customization system

**Admin Use Cases**:
- Popular item analysis
- Revenue breakdown by menu items
- Order composition insights

---

#### 6. **Eatfair.Orders.Payment** (`payments`)
**Purpose**: Financial transaction tracking

**Admin Dashboard Priority**: 🔴 **High** - Financial oversight and security

**Fields**:
- `id` (Primary Key)
- `order_id` (Foreign Key → Order, unique) - One payment per order
- `amount` (Decimal) - Transaction value
- `status` (String) - Payment state: `pending`, `processing`, `completed`, `failed`, `refunded`
- `provider_transaction_id` (String) - External payment system reference

**Admin Use Cases**:
- Financial transaction monitoring
- Payment issue resolution
- Revenue tracking and reconciliation
- Refund management
- Fraud detection and prevention

---

#### 7. **Eatfair.Restaurants.Menu** & **Meal** (`menus`, `meals`)
**Purpose**: Restaurant menu and item management

**Admin Dashboard Priority**: 🟡 **Medium** - Content oversight

**Menu Fields**:
- `name` (String) - Menu category
- `restaurant_id` (Foreign Key → Restaurant) - Ownership

**Meal Fields**:
- `name`, `description` (Strings) - Item details
- `price` (Decimal) - Pricing
- `is_available` (Boolean) - Availability status
- `menu_id` (Foreign Key → Menu) - Menu organization

**Admin Use Cases**:
- Menu content moderation
- Pricing analytics
- Popular item identification
- Restaurant menu health monitoring

---

#### 8. **Eatfair.Restaurants.Cuisine** (`cuisines`)
**Purpose**: Restaurant categorization system

**Admin Dashboard Priority**: 🟢 **Low** - Content management

**Fields**:
- `name` (String, unique) - Cuisine category name

**Admin Use Cases**:
- Cuisine category management
- Restaurant categorization analytics
- Search and discovery optimization

---

### Observability & Support Systems

#### 9. **Eatfair.Feedback.UserFeedback** (`user_feedbacks`)
**Purpose**: User feedback and development observability

**Admin Dashboard Priority**: 🔴 **High** - User support and development

**Fields**:
- `id` (Primary Key)
- `user_id` (Foreign Key → User, nullable) - Feedback attribution
- `feedback_type` (String) - `bug_report`, `feature_request`, `general_feedback`, `usability_issue`
- `message` (String) - Feedback content
- `request_id` (String) - Log correlation for debugging
- `page_url` (String) - Context location
- `version` (String) - Application version tracking
- `status` (String) - Workflow state: `new`, `in_progress`, `resolved`, `dismissed`
- `admin_notes` (String) - Internal notes

**Admin Dashboard Features** (Already implemented):
- Comprehensive feedback dashboard with filtering
- Request ID correlation for debugging
- Status workflow management
- Real-time notifications via Phoenix PubSub

---

#### 10. **Eatfair.Notifications.Event** & **UserPreference** (`notification_events`, `user_notification_preferences`)
**Purpose**: Notification system and user communication preferences

**Admin Dashboard Priority**: 🟡 **Medium** - Communication oversight

**Event Fields**:
- `event_type` (String) - Notification category
- `recipient_id` (Foreign Key → User) - Target user
- `priority` (String) - `low`, `normal`, `high`, `urgent`
- `status` (String) - Delivery status: `pending`, `sent`, `failed`, `skipped`
- `data` (Map/JSON) - Notification content
- `sent_at` (DateTime) - Delivery timestamp
- `failed_reason` (String) - Error tracking

**UserPreference Fields**:
- Channel preferences: `email_enabled`, `sms_enabled`, `push_enabled`
- Content preferences: Various notification type toggles
- Timing: `quiet_hours_start/end`, `timezone`

**Admin Use Cases**:
- Notification delivery monitoring
- Communication effectiveness analysis
- User preference insights
- System notification management

---

## 🏗️ Admin Dashboard Architecture

### Dashboard Hierarchy

1. **Main Admin Dashboard** - Platform overview and navigation
2. **User Management Dashboard** - User roles, accounts, activity
3. **Restaurant Management Dashboard** - Business oversight and support
4. **Order Management Dashboard** - Transaction monitoring and support
5. **Payment Dashboard** - Financial oversight and reconciliation
6. **Feedback Dashboard** - User support and development insights (existing)
7. **Notification Dashboard** - Communication system monitoring
8. **Analytics Dashboard** - Business intelligence and community metrics

### Key Relationships for Admin Views

```elixir
# Core business flow
User (customer) → Order → OrderItem → Meal
Order → Restaurant → User (owner)
Order → Payment (financial tracking)

# Support systems
User → Address (delivery management)
User → UserFeedback (support)
User → NotificationEvent + UserPreference (communication)

# Business categorization
Restaurant ↔ Cuisine (many-to-many)
Restaurant → Menu → Meal (menu hierarchy)
```

### Search and Filter Strategy

**Primary Search Fields**:
- Users: email, name, role
- Restaurants: name, address, city, cuisine_types
- Orders: id, status, customer email, restaurant name
- Payments: status, amount, provider_transaction_id

**Primary Filter Dimensions**:
- Users: role, confirmed_at (active), inserted_at (registration)
- Restaurants: is_open, city, cuisine_types, owner status
- Orders: status, inserted_at (date range), restaurant, customer
- Payments: status, inserted_at (date range), amount range

### Performance Considerations

**Database Indexes Needed**:
- Users: email, role, confirmed_at
- Restaurants: owner_id, is_open, city, inserted_at
- Orders: customer_id, restaurant_id, status, inserted_at
- Payments: status, inserted_at
- UserFeedback: status, feedback_type, inserted_at

**Pagination Strategy**:
- Default: 25 items per page
- Large datasets (orders, users): Stream-based pagination
- Real-time updates: Phoenix PubSub for live data

---

## 🎯 Implementation Priorities

### Phase 1: Core Management (High Priority)
1. **User Management Dashboard** - Role management, account verification
2. **Order Management Dashboard** - Transaction support and monitoring  
3. **Restaurant Management Dashboard** - Business oversight
4. **Payment Dashboard** - Financial security and reconciliation

### Phase 2: Support Systems (Medium Priority)
5. **Enhanced Feedback Dashboard** - Replace existing with comprehensive version
6. **Notification Dashboard** - Communication monitoring
7. **Analytics Dashboard** - Business intelligence

### Phase 3: Content Management (Lower Priority)
8. **Menu & Meal Management** - Content moderation
9. **Address Management** - Geographic insights
10. **Cuisine Management** - Category administration

---

*This analysis provides the foundation for implementing a comprehensive admin dashboard system that supports EatFair's mission of empowering local restaurant entrepreneurs while maintaining platform integrity and user experience.*
