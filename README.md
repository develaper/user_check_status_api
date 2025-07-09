# User Check Status API

Rails 7.1.5.1 API-only application for managing user status checks.

## Notes on the Development Approach

I’d like to use this assignment to illustrate my typical development workflow.

While the task itself is relatively simple, I’ve approached it in a way that reflects how I usually structure my work: breaking it down into clearly defined stages, each delivered through focused pull requests. This helps ensure the code is easy to read, review, and, if necessary, revert. I’ve also aimed to keep commits as atomic as possible, following best practices for version control.

From the beginning, I’ve followed a test-driven development (TDD) approach, allowing me to validate functionality early and often, and to iterate with confidence throughout the process.

## Pull Requests Overview

To illustrate my development process, I’ve divided the work into a set of focused pull requests. Each PR represents a logical step in the implementation.

- [Feature/add user check status endpoint](https://github.com/develaper/user_check_status_api/pull/1)
- [Feature/add country header security check](https://github.com/develaper/user_check_status_api/pull/2)
- [Feature/add rooted device security check](https://github.com/develaper/user_check_status_api/pull/3)
- [Feature/add security check for vpn tor](https://github.com/develaper/user_check_status_api/pull/4)

## Technical Decisions and Challenges

Beyond the functional requirements, this project served as an opportunity to demonstrate thoughtful architectural decisions and adherence to Rails best practices. Several key challenges emerged during development that influenced the technical approach.

### Service Architecture and SOLID Principles

The core challenge was designing a modular security check system that could accommodate multiple validation types while remaining maintainable and testable. I chose to implement the **Single Responsibility Principle** by creating dedicated service objects for each concern:

- `SecurityCheckService` orchestrates the overall validation flow
- `CountryWhitelistService` handles geographic restrictions
- `VpnDetectionService` manages external API integration for suspicious IP detection
- `VpnCacheService` isolates Redis caching logic from business logic

This separation allows each service to evolve independently and makes the system easier to test and debug.

### External API Integration Strategy

Integrating with VPNAPI.io presented several technical challenges around reliability and performance. The solution needed to be resilient to network failures while maintaining good user experience. I implemented a **fail-open strategy** where external service failures don't block legitimate users, combined with Redis caching to reduce API calls and improve response times.

The HTTP request logic was deliberately decomposed into focused methods (`make_vpnapi_request`, `handle_vpnapi_response`) to improve readability and testability, following the principle that methods should do one thing well.

### Caching and Performance Considerations

Given the potential for high-frequency IP checks, caching became essential. The 24-hour cache duration balances freshness with performance, while the isolated `VpnCacheService` makes it easy to adjust caching strategies or swap implementations without affecting business logic.

### Error Handling and Observability

Throughout the system, I prioritized comprehensive logging and graceful error handling. The application logs cache hits/misses, API calls, and errors at appropriate levels, making it easier to monitor and debug in production environments.

These decisions reflect my approach to building production-ready systems: anticipating failure modes, prioritizing maintainability, and ensuring the architecture can evolve with changing requirements.



## Tech Stack

- Ruby 3.2.0
- Rails 7.1.5.1 (API-only)
- PostgreSQL
- Redis (for VPN detection caching + country whitelist storage)
- HTTParty (for external API calls)
- RSpec + FactoryBot + shoulda-matchers (testing)

## Setup

### Prerequisites
- Ruby 3.2.0
- PostgreSQL
- Redis (optional for development, required for production)
- Bundler

### Installation
```bash
# Quick setup (recommended)
bin/setup

# Or manual setup
bundle install
bin/rails db:create db:migrate
bundle exec rspec  # verify setup
```

### Configuration

#### Required: VPN Detection API Key

The application uses [VPNAPI.io](https://vpnapi.io) for VPN/Tor/Proxy detection. **This is required for the security checks to work properly.**

1. **Get a free API key** from https://vpnapi.io (1,000 requests/month free)

2. **Configure the API key** using one of these methods:

**Option A: Environment Variable (Recommended for production)**
```bash
export VPNAPI_KEY="your_api_key_here"
```

**Option B: Rails Credentials (Recommended for production)**
```bash
EDITOR=nano rails credentials:edit
```
Add:
```yaml
vpnapi_key: your_api_key_here
```

**Option C: Development .env file (Recommended for development)**
```bash
# Create .env file in project root
echo "VPNAPI_KEY=your_api_key_here" > .env
```

#### Redis Configuration

**Development:** Redis is optional - the app will gracefully fall back to MockRedis if Redis is unavailable.

**Production:** Redis is recommended for optimal performance. Configure Redis URL:
```bash
export REDIS_URL="redis://localhost:6379/0"
```

If Redis is unavailable, VPN detection will still work but without caching (may be slower).

## Usage

### Development
```bash
# Start server
bin/rails server

# Run tests
bundle exec rspec

# Database operations
bin/rails db:migrate
bin/rails db:reset
```

## API Endpoints

### POST /v1/users/check_status

Check user security status and apply security validations.

**Endpoint:** `http://localhost:3000/v1/users/check_status`

#### Request Format
```json
{
  "idfa": "12345678-1234-1234-1234-123456789012",
  "rooted_device": false
}
```

#### Response Format
```json
{
  "ban_status": "not_banned"
}
```

#### curl Examples

**Basic request (should pass all checks):**
```bash
curl -X POST http://localhost:3000/v1/users/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: US" \
  -d '{
    "idfa": "12345678-1234-1234-1234-123456789012",
    "rooted_device": false
  }'
```

**Test rooted device detection:**
```bash
curl -X POST http://localhost:3000/v1/users/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: US" \
  -d '{
    "idfa": "12345678-1234-1234-1234-123456789012",
    "rooted_device": true
  }'
```

**Test country restriction (non-whitelisted country):**
```bash
curl -X POST http://localhost:3000/v1/users/check_status \
  -H "Content-Type: application/json" \
  -H "CF-IPCountry: CN" \
  -d '{
    "idfa": "12345678-1234-1234-1234-123456789012",
    "rooted_device": false
  }'
```

**Test with missing CF-IPCountry header:**
```bash
curl -X POST http://localhost:3000/v1/users/check_status \
  -H "Content-Type: application/json" \
  -d '{
    "idfa": "12345678-1234-1234-1234-123456789012",
    "rooted_device": false
  }'
```

#### Security Checks Applied
1. **Country Check**: Validates `CF-IPCountry` header against whitelist (US, CA, GB, DE)
2. **Rooted Device Check**: Blocks rooted/jailbroken devices
3. **VPN Detection**: Blocks VPN/Tor/Proxy connections via VPNAPI.io (requires API key)