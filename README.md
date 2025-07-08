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

User check status endpoint: http://localhost:3000/v1/user/check_status

*Endpoints will be documented here as they are developed.*
