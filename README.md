# User Check Status API

Rails 7.1.5.1 API-only application for managing user status checks.

## Tech Stack

- Ruby 3.2.0
- Rails 7.1.5.1 (API-only)
- PostgreSQL
- RSpec + FactoryBot + shoulda-matchers

## Setup

### Prerequisites
- Ruby 3.2.0
- PostgreSQL
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

### Generate Resources
```bash
# Model with tests
bin/rails generate model User name:string email:string

# Controller with tests  
bin/rails generate controller Api::V1::Users

# Factory
bin/rails generate factory_bot:model User
```

## API Endpoints

Base URL: `http://localhost:3000`

*Endpoints will be documented here as they are developed.*
