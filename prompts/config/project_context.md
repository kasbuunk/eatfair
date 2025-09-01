# EatFair Project Context

This file provides business domain context for all EatFair prompts.

## What is EatFair?

**Mission**: Platform that empowers local restaurant entrepreneurs by taking zero commission on orders, creating a sustainable ecosystem where restaurant owners keep 100% of their revenue.

**Vision**: Become the preferred platform for conscious consumers who want to support local restaurants while enjoying affordable, high-quality meals.

## Core User Journeys

### Consumer Journey
1. **Discovery**: Browse local restaurants by location, cuisine, ratings
2. **Menu Browsing**: View restaurant menus, prices, descriptions, availability  
3. **Ordering**: Add items to cart, customize orders, apply promotions
4. **Checkout**: Enter delivery address, select payment method, confirm order
5. **Tracking**: Monitor order status from preparation to delivery
6. **Feedback**: Rate order experience and provide reviews

### Restaurant Owner Journey  
1. **Onboarding**: Register restaurant, verify business details, set up profile
2. **Menu Management**: Add/edit menu items, prices, descriptions, availability
3. **Order Processing**: Receive orders, update status, communicate with customers
4. **Business Management**: View sales analytics, manage operating hours, delivery radius
5. **Revenue Tracking**: Monitor earnings (100% retention), track performance metrics

### Courier Journey
1. **Availability**: Set working hours and delivery areas  
2. **Order Assignment**: Receive delivery requests, accept/decline orders
3. **Pickup**: Navigate to restaurant, confirm order pickup
4. **Delivery**: Navigate to customer, complete delivery confirmation
5. **Earnings**: Track delivery earnings and performance metrics

## Business Requirements

### Core Value Propositions
- **Zero Commission**: Restaurants keep 100% of order revenue
- **Local Focus**: Support neighborhood restaurants and communities  
- **Fair Pricing**: Competitive prices for consumers without hidden fees
- **Quality Experience**: Reliable service that delights both restaurants and customers

### Success Metrics
- **Restaurant Success**: Restaurant revenue, repeat business, owner satisfaction
- **Consumer Value**: Order satisfaction, delivery reliability, price competitiveness
- **Platform Growth**: User acquisition, order frequency, market expansion
- **Community Impact**: Local business support, economic sustainability

## Technical Context

### Current State
- **Development Stage**: Feature-complete MVP (~95% completion)
- **Technology Stack**: Phoenix LiveView, Elixir, SQLite
- **Test Coverage**: 341 tests, 100% passing, comprehensive quality engineering
- **User Base**: Pre-launch, ready for production deployment
- **Focus**: Production deployment and user acquisition

### Key Features Status
- ✅ **User Authentication**: Complete with scope-based authorization and email verification
- ✅ **Restaurant Discovery**: Complete with location-based search, filtering, and address autocomplete
- ✅ **Menu Management**: Complete restaurant menu CRUD with real-time updates
- ✅ **Order Processing**: Complete end-to-end ordering flow with comprehensive tracking
- ✅ **Real-time Order Tracking**: Complete with Phoenix PubSub and status management
- ✅ **Restaurant Order Management**: Complete dashboard with order processing workflow
- ✅ **Review System**: Complete with specification-compliant order-based reviews
- ✅ **Notification System**: Extensible framework with event logging and preferences
- 🟡 **Payment Integration**: Framework ready, Stripe integration pending
- 🟡 **Delivery Coordination**: Foundation complete, courier interface pending

## Documentation References

### Active Configuration
- **Prompt Configurations**: `prompts_config/` directory
- **Current Prompts**: `prompts/` directory  
- **Development Workflows**: `prompts_config/workflows.md`
- **Quality Standards**: `prompts_config/quality_standards.md`
- **Technical Stack**: `prompts_config/tech_stack.md`
- **Security Guidelines**: `prompts_config/security.md`
- **Architecture Decisions**: `prompts_config/architecture.md`

### Archived Documentation
- **Complete Project History**: `docs/archive/` directory
- **ADR Chronology**: `docs/adr/architectural_decision_records.md`
- **Security Incidents**: `docs/security_incidents/` directory
- **Implementation Details**: `docs/archive/legacy_implementation_log.md`
- **Feature Completion History**: `docs/archive/features_completed.md`

## Quality Standards

### User Experience Priorities
1. **Restaurant Owner Success**: Platform must enable restaurant growth and profitability
2. **Consumer Satisfaction**: Reliable, fast, and affordable food ordering experience
3. **Community Benefit**: Platform contributes positively to local business ecosystem

### Technical Quality Standards  
1. **Test-Driven Development**: All features have comprehensive test coverage
2. **Performance**: Fast page loads (<200ms), responsive interactions
3. **Reliability**: System handles errors gracefully, maintains data integrity
4. **Scalability Foundation**: Architecture supports growth without major rewrites

## Business Constraints

### Early-Stage Considerations
- **Resource Efficiency**: SQLite is adequate for current scale
- **Simple Infrastructure**: Basic deployment on Fly.io sufficient  
- **Manual Processes**: Accept some manual workflows that can be automated later
- **Market Focus**: Single geographic market initially

### Revenue Model
- **Commission-Free**: Zero commission on restaurant orders (core differentiator)
- **Sustainable Funding**: Revenue through consumer delivery fees and optional services
- **Community-Driven**: Success measured by restaurant and community prosperity

This context should inform all EatFair-specific prompt customizations and decision-making.
