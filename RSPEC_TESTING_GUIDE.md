# RSpec Testing Guide for Travel Planner Project

## Overview
This document explains the RSpec test setup for the Travel Planner application. Each team member should be familiar with these tests and can extend them for additional features.

## What Was Done

### 1. **RSpec Installation & Configuration**
- Added RSpec gems to `Gemfile`:
  - `rspec-rails` - Core RSpec testing framework for Rails
  - `factory_bot_rails` - Test data factories
  - `faker` - Generate realistic fake data
  - `shoulda-matchers` - Simplified validation/association testing
  - `webmock` - Mock HTTP requests
  - `vcr` - Record and replay HTTP interactions

- Created configuration files:
  - `.rspec` - RSpec command-line configuration
  - `spec/spec_helper.rb` - General RSpec settings
  - `spec/rails_helper.rb` - Rails-specific test configuration
  - `spec/support/session_helper.rb` - Helper for simulating user login
  - `spec/support/vcr.rb` - VCR configuration for API mocking

### 2. **Factory Definitions** (`spec/factories/`)
Created factories for easy test data generation:
- `users.rb` - User factory with traits for premium, OAuth, and generation limit scenarios
- `travel_plans.rb` - Travel plan factory with status traits
- `destinations.rb` - Destination factory with safety level and location traits
- `recommendation_feedbacks.rb` - Feedback factory with like/dislike traits

### 3. **Model Specs** (`spec/models/`)

#### **User Model** (`user_spec.rb`)
Tests cover:
- ✅ Validations (name, email, password format, current_country)
- ✅ Associations (travel_plans, recommendations, destinations, feedbacks)
- ✅ Generation limits for free vs premium users
- ✅ `can_generate_recommendation?` method
- ✅ `increment_generations_used!` method
- ✅ `remaining_generations` calculation
- ✅ OAuth authentication (`from_omniauth`)
- ✅ Premium user detection
- ✅ Monthly generation count reset

#### **Travel Plan Model** (`travel_plan_spec.rb`)
Tests cover:
- ✅ Validations (dates, status, lengths)
- ✅ Date validation (end_date must be after start_date)
- ✅ Associations (user, destination)
- ✅ Itinerary serialization/deserialization
- ✅ Status filtering (planned, booked, completed, cancelled)

#### **Recommendation Feedback Model** (`recommendation_feedback_spec.rb`)
Tests cover:
- ✅ Validations (destination, feedback_type, lengths)
- ✅ Uniqueness constraint (one feedback per user per destination)
- ✅ Scopes (likes, dislikes, recent)
- ✅ `user_preferences` class method
- ✅ SQL injection prevention

#### **Destination Model** (`destination_spec.rb`)
Tests cover:
- ✅ Validations (name, city, country)
- ✅ Associations (travel_plans, users)
- ✅ Country filtering
- ✅ Safety level settings

### 4. **Controller Specs** (`spec/controllers/`)

#### **Destinations Controller** (`destinations_controller_spec.rb`)
Tests cover:
- ✅ Index action with domestic/international separation
- ✅ Show, new, edit actions
- ✅ Create action with valid/invalid params
- ✅ Update action
- ✅ Destroy action
- ✅ Flash messages and redirects

#### **Users Controller** (`users_controller_spec.rb`)
Tests cover:
- ✅ User registration (new, create)
- ✅ Password validation requirements (uppercase, lowercase, digit, special char, length)
- ✅ Email case-insensitivity
- ✅ Session management on signup
- ✅ User profile display

#### **Travel Plans Controller** (`travel_plans_controller_spec.rb`)
Tests cover:
- ✅ CRUD operations (index, show, create, update, destroy)
- ✅ User isolation (only see own travel plans)
- ✅ Status transitions (planned → booked → completed)
- ✅ Association with destinations

### 5. **Service Specs** (`spec/services/`)

#### **Travel Advisor Service** (`travel_advisor_service_spec.rb`)
Tests cover:
- ✅ Initialization with API key and host
- ✅ `places_near` method with valid coordinates
- ✅ Caching behavior
- ✅ Parameter handling (radius, limit)
- ✅ Error handling (missing params, API failures, network errors)
- ✅ Response parsing
- ✅ Logging

## How to Run the Tests

### Step 1: Install Dependencies
```bash
cd /home/bizimana61/project-travel-planner
bundle install
```

This will install all required gems including:
- rspec-rails
- factory_bot_rails
- faker
- shoulda-matchers
- webmock
- vcr
- rails-controller-testing

### Step 2: Run All Tests
```bash
bundle exec rspec
```

You should see output showing 146 examples with 0 failures (after fixes applied).
```bash
# Run all model specs
bundle exec rspec spec/models

# Run specific model spec
bundle exec rspec spec/models/user_spec.rb

# Run specific test
bundle exec rspec spec/models/user_spec.rb:25
```

### Step 3: Run Specific Test Files
```bash
bundle exec rspec --format documentation
```

### Step 4: Run with Documentation Format
```bash
# Add simplecov gem first, then run:
bundle exec rspec
```

### Step 5: Run with Coverage (optional)

Each RSpec test follows this pattern:

```ruby
RSpec.describe ModelName, type: :model do
  # 1. SET UP PRECONDITIONS
  let(:user) { create(:user) }
  
  before(:each) do
    # Setup that runs before each test
  end
  
  # 2. EXECUTE CODE & CHECK EXPECTATIONS
  it 'describes the expected behavior' do
    # Execute the code
    result = user.some_method
    
    # Check expectations
    expect(result).to eq(expected_value)
  end
end
```

### Common Expectation Matchers

```ruby
# Equality
expect(value).to eq(5)
expect(value).not_to eq(10)

# Truthiness
expect(value).to be_truthy
expect(value).to be_falsey
expect(value).to be true

# Collection matchers
expect(array).to include(item)
expect(array).to be_empty
expect(hash).to have_key(:key_name)

# Change matchers
expect { action }.to change { Model.count }.by(1)
expect { action }.to change { object.attribute }.from(old).to(new)

# Validation matchers (shoulda-matchers)
it { should validate_presence_of(:name) }
it { should validate_uniqueness_of(:email) }
it { should belong_to(:user) }
it { should have_many(:travel_plans) }
```

## How Team Members Can Verify Tests Work

### Method 1: Run Full Test Suite
```bash
bundle exec rspec
```
You should see output like:
```
User
  validations
    should validate presence of name ✓
    should validate length of name ✓
  ...

Finished in 2.5 seconds (files took 3.2 seconds to load)
85 examples, 0 failures
```

### Method 2: Run Tests by Type
```bash
# Models only
bundle exec rspec spec/models --format documentation

# Controllers only
bundle exec rspec spec/controllers --format documentation

# Services only
bundle exec rspec spec/services --format documentation
```

### Method 3: Check Individual Features
```bash
# Test user generation limits
bundle exec rspec spec/models/user_spec.rb -e "generation limits"

# Test destination controller
bundle exec rspec spec/controllers/destinations_controller_spec.rb
```

## What Each Team Member Should Do

### Team Member 1: Model Tests
- Review `spec/models/user_spec.rb`
- Add tests for any new User methods
- Understand factory usage in `spec/factories/users.rb`

### Team Member 2: Controller Tests
- Review `spec/controllers/destinations_controller_spec.rb`
- Add tests for any new controller actions
- Understand session_helper usage

### Team Member 3: Service Tests
- Review `spec/services/travel_advisor_service_spec.rb`
- Add tests for other services (OpenAI, SerpAPI, etc.)
- Learn about WebMock and VCR for API testing

### Team Member 4: Integration Tests
- Create request specs in `spec/requests/`
- Test full user workflows
- Add feature specs for critical paths

## Adding New Tests

### Example: Adding a New Model Test
```ruby
# spec/models/your_model_spec.rb
require 'rails_helper'

RSpec.describe YourModel, type: :model do
  # 1. Create test data
  let(:instance) { create(:your_model) }
  
  # 2. Test validations
  describe 'validations' do
    it { should validate_presence_of(:required_field) }
  end
  
  # 3. Test custom methods
  describe '#custom_method' do
    it 'returns expected value' do
      result = instance.custom_method
      expect(result).to eq('expected')
    end
  end
end
```

### Example: Adding a New Controller Test
```ruby
# spec/controllers/your_controller_spec.rb
require 'rails_helper'

RSpec.describe YourController, type: :controller do
  let(:user) { create(:user) }
  
  before { log_in_as(user) }
  
  describe 'GET #index' do
    it 'returns success' do
      get :index
      expect(response).to be_successful
    end
  end
end
```

## Troubleshooting

### Issue: Database Errors
```bash
# Reset test database
RAILS_ENV=test rails db:reset
RAILS_ENV=test rails db:migrate
```

### Issue: Factory Errors
```bash
# Check factories are valid
bundle exec rake factory_bot:lint
```

### Issue: Gem Conflicts
```bash
# Update bundle
bundle update rspec-rails factory_bot_rails
```

## Best Practices

1. **Follow AAA Pattern**: Arrange (setup), Act (execute), Assert (verify)
2. **One expectation per test** (when possible)
3. **Use descriptive test names** - "it 'does something specific'"
4. **Use factories** instead of fixtures
5. **Mock external APIs** with WebMock/VCR
6. **Keep tests fast** - use `build` instead of `create` when you don't need database persistence
7. **Test edge cases** - nil values, empty strings, boundary conditions
8. **Use contexts** to group related scenarios

## Resources

- [RSpec Documentation](https://rspec.info/)
- [Factory Bot Guide](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
- [Better Specs](https://www.betterspecs.org/)

## Summary

✅ RSpec is fully configured and ready to use
✅ 85+ tests covering models, controllers, and services
✅ Factories set up for easy test data generation
✅ Helper methods for common tasks (login simulation)
✅ API mocking configured with WebMock and VCR
✅ Each team member can run tests independently

**Next Steps:**
1. Run `bundle install`
2. Run `bundle exec rspec` to verify all tests pass
3. Review test files relevant to your assigned features
4. Add new tests as you develop new features
