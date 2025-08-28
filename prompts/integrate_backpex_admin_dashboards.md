# Build Custom Admin Dashboard System

*Comprehensive prompt for building a custom admin dashboard system for the EatFair Phoenix application following TDD principles and existing project patterns.*

## 🎯 Objective

Build a custom admin dashboard system using Phoenix LiveView to provide comprehensive admin capabilities for all EatFair resources, replacing and extending the current basic admin feedback interface with production-ready admin panels that support the platform's community-driven mission. This approach ensures perfect alignment with existing EatFair patterns and maintains full control over the admin experience.

## 📋 Context & Requirements

### Project Context
- **EatFair Mission**: Commission-free platform empowering local restaurant entrepreneurs
- **Architecture**: Phoenix 1.8 + LiveView with scope-based authentication
- **Database**: SQLite with Ecto schemas for all business entities
- **Development Approach**: TDD with comprehensive test coverage required
- **Admin Access Pattern**: Currently uses basic auth in dev, needs role-based access for production

### Current Admin Infrastructure
- Basic admin routes exist in `/admin` with basic auth
- Single admin LiveView: `EatfairWeb.Admin.FeedbackDashboardLive`
- Authentication uses scope system: `@current_scope.user` access pattern
- Admin role validation exists via `require_admin` on_mount hook

## 🔍 Discovery & Analysis Phase

### 1. Resource Discovery & Mapping
**Automatically discover all EatFair schemas and contexts:**

```elixir
# Schemas to analyze for custom admin integration:
- Eatfair.Accounts.User (customers, restaurant owners, couriers, admins)
- Eatfair.Accounts.Address (delivery addresses)
- Eatfair.Restaurants.Restaurant (restaurant profiles and locations)
- Eatfair.Restaurants.Cuisine (cuisine categories)
- Eatfair.Restaurants.Menu (restaurant menus)
- Eatfair.Restaurants.Meal (individual menu items)
- Eatfair.Orders.Order (customer orders with status tracking)
- Eatfair.Orders.OrderItem (individual items in orders)
- Eatfair.Orders.Payment (payment records)
- Eatfair.Feedback.UserFeedback (user feedback with observability)
- Eatfair.Notifications.Event (notification events)
- Eatfair.Notifications.UserPreference (user notification preferences)
```

**Analysis Requirements:**
1. **Schema Field Analysis**: Map each schema field to appropriate admin dashboard field types
2. **Relationship Mapping**: Identify belongs_to, has_many, many_to_many relationships 
3. **Business Logic Integration**: Preserve existing validations and changesets
4. **Permission Requirements**: Determine admin access levels needed per resource
5. **Search & Filter Needs**: Identify key fields for admin searching and filtering

### 2. Current Admin Interface Assessment
**Examine existing admin infrastructure:**
- Review `EatfairWeb.Admin.FeedbackDashboardLive` patterns
- Analyze authentication and authorization flows
- Document current admin user experience gaps
- Identify admin workflow pain points

## 🏗️ Implementation Plan

### Phase 1: Custom Admin System Foundation

#### 1.1 Admin Infrastructure Setup
**Build admin foundation using existing Phoenix patterns:**

```elixir
# Setup requirements:
# - Create admin LiveView modules following existing patterns
# - Update router.ex with comprehensive admin routes
# - Extend authentication system for fine-grained admin permissions
# - Create admin-specific components and layouts
```

#### 1.2 Authentication Integration
**Extend EatFair's scope-based auth system for admin features:**

```elixir
# Requirements:
# - Use existing @current_scope.user pattern consistently
# - Enhance require_admin on_mount hook with resource-level permissions
# - Build upon existing admin role validation
# - Support granular admin permission levels (super_admin, content_admin, etc.)
```

#### 1.3 Base Configuration
**Configure custom admin system for EatFair patterns:**
- Extend EatFair's existing TailwindCSS theme for admin interfaces
- Implement pagination and search using existing LiveView patterns
- Follow established naming conventions and project standards
- Integrate with existing error handling and observability system

### Phase 2: Core Resource Dashboards

#### 2.1 User Management Dashboard
**Comprehensive user administration:**

```elixir
# Features to implement:
- User role management (customer, restaurant_owner, courier, admin)
- Account status management (confirmed_at, authentication tracking)
- Search by email, name, role, registration date
- Filter by role, confirmation status, activity
- Bulk operations for account management
- Address relationship display and management
```

#### 2.2 Restaurant Management Dashboard
**Restaurant ecosystem oversight:**

```elixir
# Features to implement:
- Restaurant approval workflow (if needed)
- Geographic data management (coordinates, postal codes)
- Cuisine type management and validation
- Restaurant status monitoring (is_open, operational metrics)
- Owner relationship management
- Menu oversight with drill-down capabilities
- Performance metrics integration
```

#### 2.3 Order Management Dashboard
**Order lifecycle and business intelligence:**

```elixir
# Features to implement:
- Order status tracking and management
- Real-time order flow monitoring
- Payment status oversight
- Customer/restaurant relationship display
- Status transition history and analytics
- Delivery tracking and courier assignment
- Order value analytics and reporting
```

### Phase 3: Advanced Admin Features

#### 3.1 Feedback & Support Dashboard
**Enhanced user feedback management:**

```elixir
# Extend existing feedback system:
- Replace basic feedback view with custom admin dashboard
- Advanced filtering by feedback type, status, date
- Request ID correlation for debugging
- Admin workflow management (assignment, status updates)
- Integration with observability system
- Automated feedback categorization and routing
```

#### 3.2 Business Intelligence Dashboards
**Platform analytics and insights:**

```elixir
# Analytics features:
- Restaurant performance metrics
- Order volume and value tracking
- User engagement analytics
- Geographic distribution analysis
- Revenue and growth tracking
- Community impact metrics aligned with mission
```

#### 3.3 System Administration
**Technical platform management:**

```elixir
# System oversight:
- Application health monitoring
- Performance metrics dashboard
- Error tracking and resolution
- Database maintenance tools
- Security monitoring and audit logs
```

## 🧪 Test-Driven Development Requirements

### Testing Strategy
**Comprehensive test coverage following EatFair patterns:**

#### 1. Admin Dashboard Integration Tests
```elixir
# Test files to create:
- test/eatfair_web/live/admin/admin_integration_test.exs
- test/eatfair_web/live/admin/user_dashboard_test.exs  
- test/eatfair_web/live/admin/restaurant_dashboard_test.exs
- test/eatfair_web/live/admin/order_dashboard_test.exs

# Test requirements:
- Authentication and authorization validation
- CRUD operations for each resource type
- Search and filtering functionality
- Bulk operations and admin workflows
- Error handling and edge cases
- Performance with realistic data volumes
```

#### 2. User Journey Tests
```elixir
# Admin user journeys to test:
- Admin login and dashboard access
- Restaurant approval and management workflow
- Order issue investigation and resolution
- User account management and support
- Feedback processing and response workflow
- Business intelligence report generation
```

#### 3. Integration & Security Tests
```elixir
# Critical test areas:
- Admin role enforcement and privilege escalation prevention
- Data integrity during admin operations
- Audit logging of admin actions
- Performance impact of admin operations on live system
- Cross-resource relationship integrity
```

## 🎨 UI/UX Design Requirements

### Design Principles
**Align with EatFair's mission and existing UI:**

#### 1. Visual Consistency
- Use existing EatFair color scheme and typography
- Integrate with current TailwindCSS components
- Maintain accessibility standards (WCAG 2.1 AA compliance)
- Responsive design for mobile admin access

#### 2. Admin Workflow Optimization
- Prioritize common admin tasks in navigation
- Provide contextual actions based on admin role
- Implement efficient bulk operations for scale
- Clear audit trails and change tracking

#### 3. Community-Focused Features
- Highlight community impact metrics on dashboards
- Surface restaurant success stories and growth
- Provide tools for supporting local entrepreneur success
- Transparency features aligned with platform values

## 🚀 Implementation Workflow

### Step 1: Environment Preparation
```bash
# Setup commands:
1. Analyze existing schema structures and relationships
2. Plan admin LiveView architecture following existing patterns
3. Create admin module structure and base components
4. Update router.ex with comprehensive admin routes
5. Run mix test to ensure no regressions
```

### Step 2: TDD Implementation Cycle
```elixir
# For each resource (Users, Restaurants, Orders, etc.):

1. RED: Write failing tests for admin dashboard functionality
   - Authentication and access control tests
   - CRUD operation tests
   - Search and filter tests
   - Admin workflow tests

2. GREEN: Implement minimal admin dashboard functionality
   - Create admin LiveView modules following existing patterns
   - Configure fields and relationships display
   - Set up authentication integration with scope system
   - Implement search and filter capabilities

3. REFACTOR: Enhance and optimize
   - Improve admin user experience
   - Optimize queries and performance
   - Add advanced features and bulk operations
   - Enhance error handling and validation
```

### Step 3: Progressive Enhancement
```elixir
# Build admin capabilities incrementally:
1. Basic CRUD for core resources (Users, Restaurants, Orders)
2. Advanced search and filtering capabilities
3. Bulk operations and admin workflows
4. Business intelligence and analytics features
5. Advanced integrations and automation
```

## ✅ Definition of Done

### Technical Requirements
- [ ] All admin dashboards pass comprehensive test suite
- [ ] Authentication integration works with existing scope system  
- [ ] All CRUD operations maintain data integrity and validations
- [ ] Search and filtering perform well with realistic data volumes
- [ ] Admin audit logging captures all significant actions
- [ ] No regressions in existing application functionality

### User Experience Requirements
- [ ] Admin can efficiently manage all platform resources
- [ ] Dashboard provides clear insights into platform health
- [ ] Common admin workflows are streamlined and intuitive
- [ ] Error handling provides clear guidance and recovery options
- [ ] Mobile responsiveness allows admin access from any device

### Business Requirements
- [ ] Admin tools support EatFair's mission of entrepreneur empowerment
- [ ] Business intelligence features provide actionable insights
- [ ] Community impact metrics are visible and trackable
- [ ] Platform sustainability features are easily monitored
- [ ] Restaurant success and growth are measurable and supportable

### Documentation Requirements
- [ ] Admin user guide created for common workflows
- [ ] Technical documentation updated for custom admin system
- [ ] Architecture Decision Record created for admin framework choice
- [ ] Testing patterns documented for future admin feature development

## 🔧 Technical Implementation Notes

### Key Integration Points
```elixir
# Critical technical considerations:
- Preserve existing @current_scope.user authentication pattern
- Integrate with Phoenix.PubSub for real-time admin updates
- Leverage existing Ecto contexts and avoid bypassing business logic
- Use streams for large dataset administration to avoid memory issues
- Implement proper error boundaries for admin operations
- Ensure admin operations don't impact customer-facing performance
```

### Performance Considerations
```elixir
# Optimization requirements:
- Paginate all admin lists with reasonable defaults
- Implement efficient search with database indexes
- Use Ecto preloading strategically for related data
- Cache frequently accessed admin data appropriately
- Monitor and optimize admin query performance
- Implement background jobs for heavy admin operations
```

### Security Requirements
```elixir
# Security implementation:
- Validate admin permissions on every sensitive operation
- Log all admin actions for security audit trail
- Implement CSRF protection for admin forms
- Sanitize all admin inputs and prevent injection attacks
- Use proper authorization checks, not just authentication
- Implement admin session management and timeout policies
```

## 📚 Resource References

### EatFair Project Resources
- [Product Specification](../documentation/product_specification.md) - Business context and requirements
- [WARP System Constitution](../WARP.md) - Development principles and TDD workflow
- [Agent Development Guidelines](../AGENTS.md) - Phoenix/Elixir patterns and best practices
- [Definition of Done](../documentation/definition_of_done.md) - Quality criteria for completion

### Technical References
- [Backpex Documentation](https://hexdocs.pm/backpex/) - Official Backpex guides and API reference
- [Phoenix LiveView Guides](https://hexdocs.pm/phoenix_live_view/) - LiveView patterns and best practices
- [Ecto Query Guides](https://hexdocs.pm/ecto/Ecto.Query.html) - Database query optimization

## 🎯 Success Metrics

### Platform Administration Efficiency
- **Admin Task Completion Time**: Reduce common admin tasks by 70%
- **Data Discovery Speed**: Enable finding any platform data within 30 seconds
- **Error Resolution Time**: Streamline user issue resolution workflow
- **Business Intelligence Access**: Provide real-time platform health insights

### Community Impact Visibility  
- **Restaurant Success Tracking**: Monitor restaurant growth and revenue trends
- **Community Health Metrics**: Track local food ecosystem development
- **Platform Sustainability Indicators**: Monitor donation patterns and community support
- **User Satisfaction Insights**: Aggregate feedback and improvement opportunities

---

## 🚀 Getting Started

**To implement this integration:**

1. **Analyze Current State**: `mix test --trace` to ensure stable baseline
2. **Follow TDD Process**: Implement using Red-Green-Refactor cycle per resource
3. **Update Documentation**: Keep [backlog_dashboard.md](../backlog_dashboard.md) current with progress
4. **Validate Against Mission**: Ensure admin tools support entrepreneur empowerment goals

**Prerequisites:**
- Phoenix 1.8 application with LiveView
- Existing authentication system (✅ EatFair has scope-based auth)
- Database with established schemas (✅ EatFair has comprehensive Ecto schemas)
- Admin role management (✅ EatFair has admin role infrastructure)

**Expected Timeline**: 2-3 development cycles for full admin dashboard implementation

---

*This prompt aligns with EatFair's TDD approach, community-first mission, and Phoenix best practices. The implementation will provide comprehensive admin capabilities while maintaining the platform's focus on supporting local restaurant entrepreneurs.*
