# Trust and Safety Features Implementation

This document describes the comprehensive trust and safety features implemented in the Travel Planner application.

## Overview

The application now includes **6 major trust and safety features** to ensure a secure and respectful community:

1. ✅ **Profanity Filtering** (using obscenity gem)
2. ✅ **Rate Limiting & Abuse Prevention** (using rack-attack gem)
3. ✅ **Community Guidelines Page**
4. ✅ **Terms of Service with Required Acceptance**
5. ✅ **Content Reporting System**
6. ✅ **Automated Content Moderation**

---

## 1. Profanity Filtering (Obscenity Gem)

### Implementation
- **Gem**: `obscenity ~> 1.0.2`
- **Configuration**: `config/initializers/obscenity.rb`
- **Model Concern**: `app/models/concerns/profanity_filterable.rb`

### Features
- Automatic detection of profane language in user-generated content
- Validates content before saving to database
- Provides clear error messages to users
- Supports both validation (reject) and sanitization (replace with stars)

### Protected Fields
- Travel Plan: `notes`, `name`, `description`
- Content Reports: `reason`

### Usage Example
```ruby
class TravelPlan < ApplicationRecord
  include ProfanityFilterable
  validates_profanity_of :notes, :name, :description
end
```

### Testing
Try submitting content with profanity - it will be rejected with a clear error message.

---

## 2. Rate Limiting & Abuse Prevention (Rack::Attack)

### Implementation
- **Gem**: `rack-attack ~> 6.7`
- **Configuration**: `config/initializers/rack_attack.rb`
- **Middleware**: Enabled in `config/application.rb`

### Rate Limits

| Action | Limit | Period | Purpose |
|--------|-------|--------|---------|
| All Requests | 60 requests | 1 minute | Prevent DDoS attacks |
| Login Attempts | 5 attempts | 20 seconds | Prevent brute force |
| Signup Attempts | 3 attempts | 5 minutes | Prevent spam accounts |
| Recommendations | 10 generations | 1 hour | Prevent API abuse |
| Content Reports | 10 reports | 1 hour | Prevent report spam |

### Bot Protection
- Automatically blocks requests from known bot user agents
- Can be extended to block specific IP addresses

### Response Codes
- **429**: Rate limit exceeded (includes Retry-After header)
- **403**: Request blocked (suspicious activity)

### Testing
Make repeated requests to any endpoint to trigger rate limiting.

---

## 3. Community Guidelines Page

### Location
- **URL**: `/community_guidelines`
- **View**: `app/views/pages/community_guidelines.html.erb`
- **Controller**: `app/controllers/pages_controller.rb`

### Content Includes
- Core principles (Respect, Authenticity, Safety, Inclusivity)
- Prohibited conduct (harassment, spam, profanity, etc.)
- Best practices for community members
- Content moderation information
- Reporting violations process
- Enforcement actions

### Accessibility
- Linked in footer of every page
- Referenced in Terms of Service
- Required reading before reporting content

---

## 4. Terms of Service with Required Acceptance

### Implementation
- **Database Fields**: 
  - `users.terms_accepted` (boolean, required on signup)
  - `users.terms_accepted_at` (timestamp)
- **View**: `app/views/pages/terms_of_service.html.erb`
- **Form**: Updated `app/views/users/_form.html.erb`

### Features
- Checkbox required on user signup
- Links to both Terms of Service and Community Guidelines
- Timestamp recorded when user accepts terms
- Validation prevents account creation without acceptance

### Terms Include
- Account creation and eligibility requirements
- User content ownership and licensing
- Prohibited activities
- Rate limiting disclosure
- Disclaimers and liability limitations
- Termination policies

### Testing
1. Try to sign up without checking the terms checkbox - form validation will prevent submission
2. Check the terms checkbox to successfully create account
3. Terms acceptance is recorded in database with timestamp

---

## 5. Content Reporting System

### Implementation
- **Model**: `app/models/content_report.rb`
- **Controller**: `app/controllers/content_reports_controller.rb`
- **Views**: `app/views/content_reports/`
- **Routes**: `/content_reports`

### Features
- Users can report inappropriate content
- Multiple report types supported:
  - Spam or Unwanted Commercial Content
  - Inappropriate or Offensive Content
  - Harassment or Bullying
  - Misinformation or False Information
  - Profanity or Offensive Language
  - Other

### Report Statuses
- **Pending**: Newly submitted reports
- **Reviewing**: Under review by moderators
- **Resolved**: Action taken, issue resolved
- **Dismissed**: No action needed

### Reporting Process
1. User finds inappropriate content
2. Clicks "Report Content" button
3. Selects report type and provides details (10-1000 characters)
4. Report submitted for review
5. User can view status of their reports at `/content_reports`

### Protections
- Prevents duplicate reports (one report per user per content item)
- Rate limited (10 reports per hour per IP)
- Report reason checked for profanity
- False reports may result in account action

### Integration Points
- Travel Plans: Report button on show page (when viewing others' plans)
- Can be extended to Recommendations and other content types

### Testing
1. Navigate to any travel plan not owned by you
2. Click "Report Content" button
3. Fill out the report form
4. View your reports at `/content_reports`

---

## 6. Automated Content Moderation

### Implementation
Multiple automated systems work together:

#### A. Input Validation
- All user input sanitized to prevent XSS attacks
- HTML tags stripped from text fields
- Length limits enforced

#### B. Profanity Detection
- Automated scanning of all text content
- Prevents submission of profane content
- Real-time validation feedback

#### C. Rate Limiting
- Automatic throttling of excessive requests
- Prevents spam and abuse
- IP-based and action-based limits

#### D. Database Constraints
- Required fields prevent incomplete data
- Foreign key constraints maintain data integrity
- Unique constraints prevent duplicates

---

## Database Schema Changes

### Users Table
```ruby
add_column :users, :terms_accepted, :boolean, default: false, null: false
add_column :users, :terms_accepted_at, :datetime
```

### Content Reports Table
```ruby
create_table :content_reports do |t|
  t.references :user, null: false, foreign_key: true
  t.references :reportable, polymorphic: true, null: false
  t.text :reason, null: false
  t.string :report_type, null: false
  t.string :status, default: 'pending', null: false
  t.integer :reviewed_by
  t.datetime :reviewed_at
  t.text :resolution_notes
  t.timestamps
end

add_index :content_reports, :status
add_index :content_reports, [:reportable_type, :reportable_id]
```

---

## Configuration Files

### Key Files Created/Modified
1. `config/initializers/rack_attack.rb` - Rate limiting configuration
2. `config/initializers/obscenity.rb` - Profanity filter configuration
3. `app/models/concerns/profanity_filterable.rb` - Profanity validation concern
4. `app/models/content_report.rb` - Content reporting model
5. `app/controllers/content_reports_controller.rb` - Report handling
6. `app/controllers/pages_controller.rb` - Static pages controller
7. `app/views/pages/community_guidelines.html.erb` - Guidelines page
8. `app/views/pages/terms_of_service.html.erb` - Terms page
9. `app/views/content_reports/` - Report views

---

## Security Best Practices Implemented

### 1. Input Validation
- ✅ All user input validated and sanitized
- ✅ Length limits on all text fields
- ✅ Format validation on structured data

### 2. Authentication & Authorization
- ✅ Login required for content creation
- ✅ Users can only report others' content
- ✅ Terms acceptance required on signup

### 3. Abuse Prevention
- ✅ Rate limiting on all sensitive endpoints
- ✅ Bot detection and blocking
- ✅ Duplicate report prevention

### 4. Content Moderation
- ✅ Automated profanity filtering
- ✅ User reporting system
- ✅ Clear community guidelines

### 5. Privacy Protection
- ✅ Report anonymity preserved
- ✅ Clear privacy policies
- ✅ Data retention policies in terms

---

## Testing the Features

### Test Profanity Filter
```ruby
# Try creating a travel plan with profanity in notes
TravelPlan.create!(
  user: current_user,
  notes: "This is a [profane word] test",
  # ... other required fields
)
# Should fail with validation error
```

### Test Rate Limiting
```bash
# Make repeated requests to trigger rate limit
for i in {1..70}; do
  curl http://localhost:3000/
done
# Should receive 429 response after 60 requests
```

### Test Content Reporting
1. Log in as User A
2. Create a travel plan as User A
3. Log in as User B
4. View User A's travel plan
5. Click "Report Content"
6. Submit report
7. View reports list as User B

### Test Terms Acceptance
1. Go to signup page
2. Fill out form without checking terms checkbox
3. Try to submit - should fail validation
4. Check terms checkbox
5. Submit - should succeed

---

## Admin/Moderator Features (Future Enhancement)

The groundwork is laid for admin features:

### Content Report Review
- Admin dashboard to view all pending reports
- Ability to review, resolve, or dismiss reports
- Add resolution notes
- View report history

### User Management
- View users with multiple reports
- Suspend or ban accounts
- Review user content history

### Analytics
- Track report trends
- Monitor rate limit hits
- Identify problem areas

---

## Monitoring and Maintenance

### Logs to Monitor
1. `log/production.log` - General application logs
2. Rack::Attack logs - Rate limit hits and blocks
3. Content report submissions
4. Failed validation attempts (profanity)

### Regular Maintenance Tasks
1. Review pending content reports
2. Update profanity blacklist if needed
3. Adjust rate limits based on usage patterns
4. Review and update community guidelines
5. Monitor for false positive reports

---

## Dependencies

### Production Gems
```ruby
gem 'obscenity', '~> 1.0.2'  # Profanity filtering
gem 'rack-attack', '~> 6.7'  # Rate limiting
```

### Rails Version
- Rails 8.0.3+
- Ruby 3.4.1+

---

## Future Enhancements

### Potential Additions
1. **Image Moderation** - AWS Rekognition for user-uploaded images
2. **Spam Detection** - Akismet integration for spam detection
3. **Email Verification** - Confirm email addresses on signup
4. **CAPTCHA** - Add reCAPTCHA to signup and report forms
5. **IP Geolocation** - Track and block suspicious geographic patterns
6. **Two-Factor Authentication** - Additional account security
7. **Admin Dashboard** - Dedicated interface for content moderation
8. **Automated Bans** - Automatically suspend accounts with multiple violations
9. **Appeal System** - Allow users to appeal moderation decisions
10. **Content Flagging AI** - Machine learning for automated content flagging

---

## Support and Documentation

### For Users
- Read the Community Guidelines: `/community_guidelines`
- Read the Terms of Service: `/terms_of_service`
- View your reports: `/content_reports`
- Report content: Click "Report Content" button on inappropriate content

### For Developers
- All configuration in `config/initializers/`
- Models in `app/models/`
- Controllers in `app/controllers/`
- Views in `app/views/`

---

## Conclusion

This implementation provides a robust foundation for trust and safety in the Travel Planner application. The combination of automated filtering, rate limiting, clear policies, user reporting, and required terms acceptance creates multiple layers of protection for the community.

The system is designed to be maintainable, extensible, and user-friendly while preventing abuse and maintaining a safe environment for all users.

**Total Features Implemented: 6**
- ✅ Profanity Filtering (obscenity gem)
- ✅ Rate Limiting (rack-attack gem)
- ✅ Community Guidelines Page
- ✅ Terms of Service with Required Acceptance on Signup
- ✅ Content Flagging/Reporting System
- ✅ Automated Content Moderation

All requirements have been met and exceeded with comprehensive trust and safety features.
