# EatFair Project Specification

## Vision Statement

EatFair exists to empower small restaurant entrepreneurs by providing a commission-free platform that connects consumers directly with local restaurants, ensuring restaurant owners capture the full value of their offerings while fostering thriving local food communities.

## Mission

To eliminate the exploitative commission structures of existing food delivery platforms and create a sustainable ecosystem where:
- Restaurant owners retain 100% of their revenue
- Consumers enjoy competitive pricing and exceptional service
- Local food entrepreneurs can build and grow their businesses freely
- Community members can support their local economy directly

## Core Values

- **Entrepreneur Empowerment**: Every feature should strengthen local restaurant owners' ability to build sustainable businesses
- **Community First**: Prioritize local economic growth over platform extraction
- **Excellence Over Scale**: Deliver exceptional user experience rather than rushing geographic expansion
- **Transparency**: Clear, honest communication about costs, policies, and platform operations
- **Universal Accessibility**: Ensure the platform works for diverse communities across demographics, languages, technical comfort levels, and accessibility needs
- **Faith in Community**: Operate on the belief that people will support valuable community services

## Primary User Groups

### 1. Restaurant Owners
Small, locally-owned restaurant entrepreneurs who want to:
- Reach more customers without surrendering significant revenue
- Maintain control over their customer relationships
- Access professional-grade online ordering tools
- Build their brand and customer loyalty

### 2. Consumers
Local community members who want to:
- Support their neighborhood restaurants
- Enjoy convenient food ordering and delivery
- Access transparent pricing without hidden fees
- Discover new local dining options

### 3. Couriers
Independent delivery partners who want to:
- Earn fair compensation for delivery services
- Work flexible schedules
- Serve their local community
- Receive transparent payment terms

## Core Platform Features

### Restaurant Management System
- **Business Profile Management**: 
  - Complete restaurant information with specific address (separate from invoice address)
  - Contact information (phone, email)
  - Restaurant branding, story, and values
  - Restaurant description displayed on public detail pages
  - Image upload system for restaurant photos (secure, malware-checked, S3-compatible storage)
  - Default images per cuisine type with option to override
- **Menu Management**: 
  - Full menu creation, editing, categorization, and pricing control
  - Meal customization options (toppings, preferences, dietary modifications)
- **Operational Controls**: 
  - Standard and exceptional opening hours
  - Delivery zones (postal codes, radius-based, or time-based - extensible system)
  - Capacity management and temporary closures
  - Order confirmation policy (auto-confirm or manual review)
  - Order refusal capability with optional messaging
- **Order Management**: 
  - Real-time order processing with confirmation workflow
  - Preparation time estimates and customer communication
  - Order status updates and delivery coordination
- **Review Management System**:
  - Overview of all customer reviews with ratings
  - Response capability with optional emoji and text replies
  - Review analytics and sentiment tracking
- **Courier Management**:
  - Dashboard showing affiliated couriers (restaurant-approved)
  - Real-time delivery status of all active orders
  - Courier availability and current load indicators
- **Feedback System**:
  - Built-in feedback form for restaurant owners
  - Feature requests and general feedback collection
  - Direct communication channel with platform team
- **Financial Dashboard**: Revenue tracking, payout management, and financial reporting
- **Analytics**: Customer insights, popular items, peak hours, and business performance metrics
- **Consumer Ordering Experience**:
- **Intelligent Restaurant Discovery**: 
  - Location-based relevance scoring that prioritizes nearby restaurants
  - Immediate location detection (postal/zip code input, browser geolocation, IP fallback, Amsterdam Central Station default)
  - Pre-filled location data for authenticated users
  - Real-time search results that update when location changes
  - Complete exclusion of irrelevant far-away restaurants from results
  - Geographic map interface with restaurant pins showing cuisine type and direct links to detail pages
  - **Location Persistence**: Searched locations persist across page refreshes and navigation
  - **Formatted Address Display**: Show Google Maps formatted addresses instead of raw user input
  - **Location Refinement System**: Clear user journey to change or refine delivery address with real-time delivery feedback
- **Advanced Filter System**: 
  - Multi-select cuisine filters with modern categories (not archaic local/european vs asian/international)
  - Aligned cuisine types between restaurant registration and consumer filtering
  - Specific food type filters transcending cuisines (pizza, sushi, burgers, healthy bowls)
  - Appetite-based discovery beyond generic cuisine categories
  - Intuitive collapsible filter interface that stays out of the way until needed
  - Filters for price range, dietary restrictions, delivery time, and restaurant ratings
  - Filters for price range, dietary restrictions, delivery time, and restaurant ratings
- **Personalized Recommendations**: Based on order history, preferences, and community trends
- **Detailed Menu Browsing**: Rich item descriptions, customization options, allergen information
- **Review-Rich Restaurant Pages**: 
  - Display customer reviews prominently on restaurant detail pages
  - Show average ratings calculated dynamically from actual customer reviews (no manual entry)
  - Include reviews from verified customers who have completed orders
  - Handle restaurants with no reviews gracefully with appropriate messaging
  - Display restaurant description prominently on detail pages
- **Enhanced Restaurant Detail Page Experience**:
  - **Clear Delivery Status Display**: Show prominent delivery status with user-friendly messaging
  - **Formatted Location Display**: Display Google Maps formatted address instead of raw user input  
  - **Location Precedence**: Searched location always takes precedence over user's saved addresses
  - **Delivery Address Refinement**: Clear option to change or refine delivery address with real-time feedback
  - **Contextual Messaging**: When delivery unavailable, show clear explanation and next steps
  - **Seamless Cart Integration**: Enable/disable ordering based on actual delivery availability
  - **Session Persistence**: Maintain location context across page refreshes and browser sessions
- **Streamlined Ordering**: 
  - Cart management with meal customization options
  - Special instructions and dietary preferences
  - Streamlined checkout process
- **Order Tracking**: Real-time updates from preparation through delivery with delivery route position and ETA
- **Account Management**: 
  - Multiple addresses (delivery and invoice)
  - Payment methods and dietary preferences
  - Order history and loyalty tracking
  - Personalized dashboard based on user type (consumer vs restaurant owner)
  - Restaurant owners see 'My Restaurant Dashboard' instead of 'Start Your Restaurant' when logged in

### Delivery Coordination System
- **Courier Onboarding**: Application, verification, and training processes
- **Courier Interface**: 
  - Dedicated courier dashboard showing available deliveries to pick up
  - Multi-delivery route optimization with flexible deviation options
  - Delivery management showing customer address, delivery notes, phone number, and order identification
  - Simple approval system requiring restaurant confirmation for new couriers
  - Real-time delivery status updates with customer ETA communication
- **Dynamic Dispatch**: Intelligent matching of orders to available couriers
- **Transparent Compensation**: Restaurant-set delivery fees with no platform extraction
- **Route Optimization**: Efficient delivery planning and navigation support with traffic awareness
- **Consumer Delivery Tracking**: 
  - Real-time courier location updates
  - Position tracking in multi-delivery routes ("You are delivery #2 of 4")
  - Dynamic ETA updates based on current route progress
  - Status updates from pickup through delivery completion
- **Performance Tracking**: Delivery metrics and feedback systems
- **Community-Driven Service**: Free coordination service to support local entrepreneurship

### Community Features
- **Rating and Review System**: Post-delivery feedback for restaurants and service quality
- **Loyalty Programs**: Restaurant-specific and platform-wide rewards for frequent customers
- **Local Food Community**: Discovery features highlighting neighborhood food culture
- **Platform Support Integration**: Thoughtfully-timed opportunities for users to donate to platform sustainability
- **Social Responsibility**: Options for customers to support local food banks or community initiatives

## Advanced Capabilities

### Geographic and Cultural Adaptation
- **International Address Support**: Flexible addressing systems for future expansion
- **Multi-language Platform**: Localized interfaces and content
- **Currency and Payment Flexibility**: Regional payment methods with future cryptocurrency support
- **Cultural Food Preferences**: Dietary restriction filters and cultural cuisine categorization

### Quality Assurance and Trust
- **Restaurant Verification**: Identity and business legitimacy confirmation
- **Customer Support**: Comprehensive help system, complaint resolution, and communication channels
- **Quality Monitoring**: Service standards, delivery performance, and user experience tracking
- **Safety Standards**: Food handling, delivery protocols, and emergency procedures

### Technology Integration
- **Location Intelligence**: Accurate delivery zone mapping and real-time location services
- **Notification System**: Real-time updates for all user types across multiple channels
- **Data Analytics**: Business intelligence for restaurants and platform optimization
- **API Ecosystem**: Integration capabilities for POS systems, accounting software, and other business tools

### Secure File Upload & Storage System
**Priority**: Post-MVP (Security-Critical Implementation)

#### Core Requirements
- **File Type Validation**: Strict whitelist of allowed image formats (JPEG, PNG, WebP)
- **Malware Detection**: Automated scanning of all uploaded files for security threats
- **File Size Limits**: Reasonable size restrictions to prevent abuse and storage costs
- **Image Processing**: Automatic optimization, resizing, and format conversion for web delivery
- **Content Moderation**: Automated and manual review processes for inappropriate content

#### Storage Architecture
- **S3-Compatible Storage**: Design for easy migration to cloud storage services (AWS S3, DigitalOcean Spaces, etc.)
- **CDN Integration**: Fast global delivery of restaurant images
- **Backup Strategy**: Redundant storage to prevent data loss
- **Access Control**: Secure URLs with proper permissions and expiration

#### Security Measures
- **Sandboxed Processing**: Isolated environment for image processing operations
- **File Quarantine**: Temporary isolation of uploads during security scanning
- **Audit Logging**: Complete tracking of all file operations for security monitoring
- **Rate Limiting**: Upload frequency limits to prevent abuse

#### Implementation Considerations
- **Local Development**: Simple local storage for development with production-ready interfaces
- **Progressive Enhancement**: Start with basic upload, add advanced security features iteratively
- **Cost Management**: Efficient storage and bandwidth usage to keep platform sustainable
- **Legal Compliance**: GDPR-compliant handling of user-uploaded content

*This feature is essential for restaurant branding but requires careful security implementation. Planned for post-MVP to ensure proper security architecture.*

### Accessibility & Universal Design
- **Visual Accessibility**: 
  - High contrast mode with systematically improved dark theme readability
  - Font size scaling and screen reader compatibility
  - Color-blind friendly design patterns
- **Interaction Accessibility**: 
  - Full keyboard navigation support
  - Touch-friendly mobile interfaces
  - Voice input compatibility for ordering
- **Cognitive Accessibility**: 
  - Clear, simple language throughout the interface
  - Consistent navigation patterns
  - Error prevention and recovery guidance
- **Technical Accessibility**: 
  - WCAG 2.1 AA compliance as measurable goal
  - Semantic HTML structure for assistive technologies
  - Automated accessibility testing in development pipeline

### User Feedback & Community Engagement
- **Feedback Collection System**: 
  - Context-sensitive feedback requests throughout user journeys
  - Database-stored feedback with admin notification triggers
  - A/B testing framework for optimal feedback timing
- **Continuous Improvement Loop**: 
  - User feedback analysis and categorization
  - Direct integration of feedback into development priorities
  - Feedback response system to close the loop with users
- **Community Input Integration**: 
  - Restaurant owner feedback on platform features
  - Consumer experience improvement suggestions
  - Courier workflow optimization based on field experience

### User Feedback & Observability System
**Priority**: Core Application Goal (Development Tooling)  
**Purpose**: Enable rapid troubleshooting of user-reported issues in development environment

#### Core Requirements
- **Software Version Tracking**: Application version included in all telemetry events and logs for debugging version-specific issues
- **Enhanced Built-in Observability**: Leverage BEAM/Phoenix defaults with structured logging to file, request_id correlation, and minimal OpenTelemetry configuration
- **Simple User Feedback System**: 
  - UserFeedback schema with feedback_type, message, request_id, user_id, page_url, version, status, admin_notes, timestamps
  - Floating feedback widget (LiveView component) that captures Phoenix request_id automatically
  - Real-time feedback submission with context capture
- **Development-First Admin Interface**: 
  - Simple admin page listing feedback with request_id lookup capability
  - Email notifications using existing Swoosh setup
  - Real-time updates via Phoenix.PubSub (already configured)
- **Request Correlation**: Use existing Phoenix request_id as correlation mechanism for linking user feedback to application logs

#### Implementation Philosophy
- **Leverage Existing Phoenix Features**: Use built-in Phoenix.Logger, request_id, telemetry, and LiveView real-time features
- **Minimal Configuration Changes**: Basic file logging output, version metadata, and simple OpenTelemetry setup
- **Development-Focused**: Optimized for localhost:4000 troubleshooting workflow
- **Standard Phoenix Patterns**: Use established LiveView, context, and PubSub patterns throughout

#### Post-MVP Goals
- **Production Log Querying**: Remote log access and aggregation (requires different AI agent capabilities)
- **Advanced OpenTelemetry Integrations**: Complex tracing and metrics collection
- **Log Aggregation Services**: Integration with external logging platforms

*This system serves as essential development tooling for troubleshooting user-reported issues by correlating feedback with application logs via request_id.*

### Platform Sustainability & Support
- **Donation System Architecture**: 
  - Multi-user donation prompts (customers, restaurant owners, couriers)
  - A/B testing framework for donation timing and messaging optimization
  - Transparent donation usage reporting and community impact metrics
- **Payment Integration**: 
  - Seamless donation processing alongside order payments
  - Multiple donation amount options and subscription support
  - Clear messaging about zero-commission policy and community support model

### Search Engine Optimization & Discoverability
- **Restaurant SEO Foundation**: 
  - Individual restaurant pages optimized for local search
  - Structured data markup for restaurant information (Schema.org)
  - Meta tag optimization for social media sharing
- **Local Search Optimization**: 
  - Geographic SEO targeting for delivery areas
  - Integration with local business directories
  - Cuisine-specific landing pages for organic discovery
- **Content Marketing Framework**: 
  - Restaurant spotlight features for community engagement
  - Local food culture content to drive organic traffic
  - SEO-optimized content architecture for sustainable growth

### Advanced Restaurant Analytics
- **Business Intelligence Dashboard**: 
  - Order history analysis with trend identification
  - Customer loyalty metrics and retention analytics
  - Revenue optimization recommendations based on data patterns
- **Market Intelligence**: 
  - Price elasticity analysis and competitive positioning
  - Peak time optimization and capacity planning
  - Seasonal trend analysis for menu planning
- **Customer Insights**: 
  - Customer acquisition and retention analytics
  - Order pattern analysis and personalization opportunities
  - Consumer dropout rate analysis with improvement recommendations
- **Performance Metrics**: 
  - Traffic analysis and conversion optimization
  - Restaurant exposure metrics and visibility optimization
  - Administrative analytics for operational efficiency

### Advanced Testing & Quality Assurance
- **Comprehensive Testing Strategy**: 
  - High-level integration testing with realistic seed data
  - Automated user journey testing across all user types
  - Cross-browser and device compatibility testing
- **Performance & Load Testing**: 
  - Realistic load testing with dozens of concurrent users
  - Database performance testing with large datasets
  - Real-world scenario testing with complex user interactions
- **Automated Quality Assurance**: 
  - Continuous integration testing with comprehensive coverage
  - Automated accessibility testing integration
  - Performance regression testing and monitoring

## Platform Sustainability Model

### Revenue Structure
- **Zero Commission Policy**: Restaurants retain 100% of food sales revenue
- **Community Donations**: Voluntary contributions from all platform users (consumers, restaurant owners, couriers) who value the service
- **Mission-Driven Operations**: Platform operates on belief in community goodness and value creation, rather than profit extraction and value capture

### Growth Strategy
- **Excellence-First Launch**: Focus on delivering exceptional user experience over geographic expansion
- **Local Community Foundation**: Begin in Het Gooi region (Netherlands), expanding to Amsterdam and Utrecht
- **Restaurant-First Approach**: Prioritize restaurant owner satisfaction to drive organic growth
- **Organic Geographic Expansion**: Let successful communities drive expansion rather than forced scaling
- **Word-of-Mouth Growth**: Leverage entrepreneur networks and community connections
- **Value Demonstration**: Clear ROI communication showing savings versus commission-based platforms

## Success Metrics

### Primary Indicators
- **Restaurant Retention**: Percentage of restaurants actively using platform after 6 months
- **Revenue Growth**: Average monthly revenue increase for participating restaurants
- **Community Engagement**: Customer repeat order rates and platform loyalty
- **Market Penetration**: Platform adoption rate in target geographic markets

### Secondary Indicators
- **Customer Satisfaction**: Net Promoter Score and review ratings
- **Delivery Performance**: On-time delivery rates and customer experience scores
- **Platform Reliability**: Uptime, transaction success rates, and technical performance
- **Social Impact**: Local economic impact and small business growth facilitated

## MVP Philosophy

The initial release must deliver an excellent user experience for both consumers and restaurant owners rather than compromising quality for feature breadth. If the full feature set cannot be achieved initially, the platform should limit geographic scope or user base rather than deliver a subpar experience. Excellence is essential for achieving the growth velocity needed for long-term success.

## Post-MVP Feature Roadmap

### Advanced Menu Customization System
**Priority**: Phase 2 Enhancement  
**Complexity**: High - Requires careful UX and data modeling

#### Feature Requirements
- **Meal Customization Options**: Toppings, sauces, cooking preferences, portion sizes
- **Pricing Models**: Fixed price additions, percentage-based pricing, quantity-based pricing
- **Option Types**: 
  - Binary (with/without - e.g., "Add cheese +€2")
  - Quantity-based (0-5 scale - e.g., "Spice level: Mild to Very Hot")
  - Single selection (choose one - e.g., "Sauce: Marinara, Alfredo, or Pesto")
  - Multiple selection (choose many - e.g., "Toppings: Mushrooms, Peppers, Olives")
- **Business Logic**: Minimum/maximum selections, mutually exclusive options, conditional availability
- **Integration Points**: Cart calculations, order processing, kitchen instructions, pricing display

#### Implementation Considerations
- Complex schema relationships (meal → customization_groups → options)
- Dynamic pricing calculations in real-time
- Mobile-friendly interface for option selection
- Kitchen workflow integration for custom order preparation
- Analytics on popular customization choices

*This feature significantly increases order value and customer satisfaction but requires substantial development investment. Postponed to focus on core MVP functionality.*

### Dynamic Delivery Time Estimation
**Priority**: Phase 2 Enhancement  
**Complexity**: High - Requires real-time data integration

#### Feature Requirements
- **Dynamic Preparation Time**: Adjust based on kitchen capacity, current orders, meal complexity
- **Peak Time Management**: Automatic time adjustments during busy periods
- **Delivery Route Optimization**: Integration with mapping services for accurate delivery estimates
- **Real-time Updates**: Live estimation updates as conditions change
- **Capacity Management**: Order throttling when kitchen reaches capacity limits

#### Implementation Considerations
- Integration with mapping APIs (Google Maps, MapBox)
- Real-time kitchen load monitoring
- Machine learning for preparation time prediction
- Customer communication for expectation management
- Restaurant dashboard for capacity control

*Critical for scale but complex to implement. MVP will use simple static estimates with manual adjustments.*

---

## Future Vision

EatFair aspires to become the standard platform that local food communities use to support their neighborhood restaurants, creating a sustainable alternative to extractive marketplace models. The platform should demonstrate that technology can serve community empowerment rather than concentrate market power, inspiring similar approaches across industries.

Success means that when someone thinks about ordering food, they think about supporting their local restaurant owner directly, not enriching a distant corporation. EatFair should become synonymous with community-conscious consumption and entrepreneur empowerment.

The platform's sustainability depends on the community's recognition of its value, expressed through voluntary support rather than forced fees. This model proves that ethical business practices can create lasting, beneficial relationships between technology platforms and the communities they serve.

---

*This specification serves as the foundational document for all development, feature, and strategic decisions. All implementation choices should advance these core goals and values.*
