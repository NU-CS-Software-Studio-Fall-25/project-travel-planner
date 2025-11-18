# Like/Dislike Recommendation Feature

## Overview
This feature allows users to provide feedback on travel recommendations by liking or disliking them. The system learns from this feedback to provide better, more personalized recommendations in the future.

## Implementation Details

### 1. Database Schema

**Migration**: `db/migrate/20250109000001_create_recommendation_feedbacks.rb`

Creates the `recommendation_feedbacks` table with:
- `user_id` - Foreign key to users table
- `destination_city` - The city that was recommended
- `destination_country` - The country of the destination
- `trip_type` - Type of trip (Solo, Couple, Family, Group)
- `travel_style` - Travel style (Budget, Moderate, Luxury, etc.)
- `budget_min` and `budget_max` - Budget range for the trip
- `length_of_stay` - Duration in days
- `feedback_type` - Either 'like' or 'dislike'
- `reason` - Optional text explaining why (max 500 chars)
- Unique index on `(user_id, destination_city, destination_country)` - prevents duplicate feedback

### 2. Model Layer

**File**: `app/models/recommendation_feedback.rb`

**Validations**:
- Presence: user_id, destination_city, destination_country, feedback_type
- Length limits: 
  - city/country: 100 characters (prevents XSS/buffer attacks)
  - reason: 500 characters
- Inclusion: feedback_type must be 'like' or 'dislike'
- Uniqueness: One feedback per user per destination

**Scopes**:
- `likes` - Returns all liked feedbacks
- `dislikes` - Returns all disliked feedbacks
- `recent` - Returns feedbacks ordered by most recent

**Class Methods**:
- `user_preferences(user_id)` - Returns hash with:
  - `liked_destinations` - Array of {city, country, travel_style, trip_type, length_of_stay}
  - `disliked_destinations` - Same structure as liked
  - `preferred_styles` - Travel styles the user tends to like
  - `avoided_styles` - Travel styles the user tends to dislike

**Association**:
- `app/models/user.rb` - Added `has_many :recommendation_feedbacks, dependent: :destroy`

### 3. Controller Layer

**File**: `app/controllers/recommendation_feedbacks_controller.rb`

**Actions**:

1. **create** (POST /recommendation_feedbacks)
   - Accepts JSON feedback data
   - Validates and sanitizes input (strips whitespace, enforces length limits)
   - Updates existing feedback if user already rated this destination
   - Creates new feedback otherwise
   - Returns JSON: `{success: true/false, message: string, feedback_type: string}`

2. **destroy** (DELETE /recommendation_feedbacks/:id)
   - Removes feedback by ID
   - Only allows users to delete their own feedback (security)
   - Returns JSON: `{success: true/false, message: string}`

3. **index** (GET /recommendation_feedbacks)
   - Shows user's feedback history
   - Groups by liked/disliked
   - Limits to 50 most recent

**Security Features**:
- `before_action :require_login` - Authentication required
- `sanitize_feedback_params` - Strips whitespace, enforces length limits
- Authorization check - Users can only manage their own feedback
- Strong parameters - Whitelist only allowed fields

### 4. Routes

**File**: `config/routes.rb`

```ruby
resources :recommendation_feedbacks, only: [:create, :destroy, :index]
```

### 5. View Layer

#### Like/Dislike Buttons
**File**: `app/views/travel_recommendations/_recommendations_list.html.erb`

**Features**:
- Button group with thumbs up/down icons
- Data attributes store recommendation details (city, country, trip_type, etc.)
- AJAX submission with CSRF token protection
- Visual feedback:
  - Green (btn-success) when liked
  - Red (btn-danger) when disliked
  - Outline buttons (btn-outline) when neutral
- Success/error messages display inline
- Buttons disabled during submission to prevent duplicate requests

**JavaScript Functions**:
- `initializeFeedbackButtons()` - Attaches click handlers to all like/dislike buttons
- `submitFeedback(data, buttonElement)` - Sends AJAX POST request
- `showFeedbackMessage(container, message, type)` - Displays auto-dismissing alerts
- Uses `escapeHtml()` for XSS prevention

#### Feedback History View
**File**: `app/views/recommendation_feedbacks/index.html.erb`

**Features**:
- Two-column layout: Liked (green) and Disliked (red)
- Each feedback shows:
  - Destination name (city, country)
  - Trip details (type, style, duration)
  - Optional reason text
  - Time since feedback was given
  - Remove button
- All content sanitized with `sanitize()` helper
- Bootstrap cards with color-coded headers
- Empty state messages when no feedback exists

### 6. AI Integration

**File**: `app/Services/openai_service.rb`

**New Method**: `build_user_feedback_context(user_id)`

Fetches user preferences and formats them into a prompt section:

```
📝 USER LEARNING CONTEXT - Use this to personalize recommendations:

✅ DESTINATIONS THE USER LIKED (consider similar places):
   - Paris, France (Luxury, Couple, 5 days)
   - Rome, Italy (Cultural, Solo, 7 days)

❌ DESTINATIONS THE USER DISLIKED (avoid similar places):
   - Las Vegas, United States (Budget, Group, 3 days)

⭐ PREFERRED TRAVEL STYLES: Luxury, Cultural
⛔ AVOIDED TRAVEL STYLES: Budget

🎯 IMPORTANT: Use this feedback to suggest destinations similar to what the user liked...
```

**Integration**:
- `build_prompt` method calls `build_user_feedback_context(@preferences[:user_id])`
- Context inserted at top of prompt (after greeting, before budget validation)
- Controller passes `user_id` to OpenaiService: `preferences[:user_id] = current_user.id`

**Benefits**:
- AI learns user's destination preferences
- Suggests similar cities/countries to liked ones
- Avoids suggesting destinations similar to disliked ones
- Considers preferred travel styles
- Improves recommendation relevance over time

### 7. Security Considerations

✅ **Input Validation**:
- Length limits prevent buffer overflow attacks
- Whitespace stripping prevents formatting abuse
- Type coercion (to_i) for numeric fields

✅ **XSS Prevention**:
- All output sanitized with `sanitize()` helper
- JavaScript uses `escapeHtml()` for dynamic content
- Data attributes instead of inline onclick handlers

✅ **CSRF Protection**:
- Rails authenticity tokens on all forms
- AJAX requests include 'X-CSRF-Token' header

✅ **Authorization**:
- Users can only create/delete their own feedback
- `current_user` association enforced in controller

✅ **SQL Injection**:
- ActiveRecord parameterized queries
- No raw SQL with user input

### 8. Usage Flow

1. **User generates recommendations**
   - Fills out travel preferences form
   - Submits and receives AI recommendations

2. **User provides feedback**
   - Clicks "Like" or "Dislike" on a recommendation card
   - Button changes color to show current state
   - Feedback saved to database
   - Success message appears

3. **User generates new recommendations**
   - System fetches user's feedback history
   - AI receives personalized context
   - AI suggests destinations similar to liked ones
   - AI avoids destinations similar to disliked ones

4. **User views feedback history**
   - Visits `/recommendation_feedbacks`
   - Sees all liked/disliked destinations
   - Can remove feedback to reset preferences

### 9. Testing the Feature

**Steps to verify**:

1. Run migration:
   ```bash
   bin/rails db:migrate
   ```

2. Start server and login

3. Generate travel recommendations

4. Click "Like" on one recommendation
   - Verify button turns green
   - Check database: `RecommendationFeedback.last`

5. Click "Dislike" on another recommendation
   - Verify button turns red

6. Generate new recommendations with same preferences
   - AI should avoid disliked destinations
   - AI should suggest similar to liked destinations

7. Visit `/recommendation_feedbacks`
   - Verify liked/disliked destinations appear
   - Test "Remove" button

8. Security tests:
   - Try submitting feedback without login (should fail)
   - Try deleting another user's feedback (should fail)
   - Try XSS in reason field (should be sanitized)

### 10. Future Enhancements

**Potential improvements**:
- Collaborative filtering (recommend destinations liked by similar users)
- Sentiment analysis on reason text
- Feedback on specific aspects (hotel, activities, food)
- Machine learning model for better pattern recognition
- Export feedback history
- Feedback analytics dashboard for users
- Integration with saved travel plans

## Migration Instructions

1. Ensure you're on the `like-dislike-rec` branch
2. Run `bin/rails db:migrate`
3. Restart your Rails server
4. Test the feature thoroughly
5. Commit changes: `git add . && git commit -m "Add like/dislike recommendation feature"`
6. Push to remote: `git push origin like-dislike-rec`
7. Open Pull Request on GitHub
8. After review, merge into main branch

## Files Created/Modified

**Created**:
- `db/migrate/20250109000001_create_recommendation_feedbacks.rb`
- `app/models/recommendation_feedback.rb`
- `app/controllers/recommendation_feedbacks_controller.rb`
- `app/views/recommendation_feedbacks/index.html.erb`
- `LIKE_DISLIKE_FEATURE.md` (this file)

**Modified**:
- `app/models/user.rb` - Added `has_many :recommendation_feedbacks`
- `config/routes.rb` - Added feedback routes
- `app/views/travel_recommendations/_recommendations_list.html.erb` - Added like/dislike buttons
- `app/Services/openai_service.rb` - Added user feedback integration
- `app/controllers/travel_recommendations_controller.rb` - Pass user_id to AI service

## Dependencies

- Rails 8.0.3
- Ruby 3.4.1
- OpenAI API (GPT-4)
- Bootstrap 5 (for UI)
- Turbo (for AJAX)

All dependencies are already present in the project. No additional gems required.
