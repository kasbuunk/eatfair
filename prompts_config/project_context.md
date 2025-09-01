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
- **Development Stage**: Early-stage MVP (~65% completion)
- **Technology Stack**: Phoenix LiveView, Elixir, SQLite
- **User Base**: Pre-launch (no production users yet)
- **Focus**: Feature completion and production readiness

### Key Features Status
- ✅ **User Authentication**: Complete with scope-based authorization
- ✅ **Restaurant Discovery**: Location-based search and filtering  
- ✅ **Menu Management**: Restaurant owners can manage menu items
- 🟡 **Order Processing**: Basic ordering flow implemented
- 🔴 **Payment Integration**: Planned but not implemented
- 🔴 **Delivery Tracking**: Planned but not implemented
- 🔴 **Review System**: Needs specification compliance fixes

## Documentation References

- **Product Requirements**: `documentation/product_specification.md`
- **Implementation Status**: `documentation/legacy_implementation_log.md` 
- **Architecture Decisions**: `documentation/architectural_decision_records.md`
- **Feature Completion**: `documentation/features_completed.md`

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
