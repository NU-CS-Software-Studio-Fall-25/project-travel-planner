# Bug Fix: Safety Preference Not Being Passed to Backend

## Problem
User selected "Level 4 - Extreme Risk (Not Safe)" but received recommendations for "Very Safe" countries like New Zealand (GPI: 1.282).

## Root Cause
The controller's `travel_plan_params` method was still configured for the old checkbox system (`safety_levels: []`) and was NOT permitting the new `safety_preference` parameter.

This meant that when the form submitted:
```ruby
"safety_preference" => "Not Safe"
```

The controller was **silently dropping this parameter** because it wasn't in the permitted list!

As a result, `@preferences[:safety_preference]` was `nil`, and the OpenAI Service was getting ALL countries instead of filtering by safety level.

## The Fix

**Before (Wrong):**
```ruby
def travel_plan_params
  params.require(:travel_plan).permit(
    :name, :passport_country, :current_location, :budget_min, :budget_max,
    :length_of_stay, :travel_style, :travel_month, :trip_scope, :trip_type,
    :general_purpose, :start_date, :end_date,
    safety_levels: []  # ❌ Old parameter, no longer used
  )
end
```

**After (Correct):**
```ruby
def travel_plan_params
  params.require(:travel_plan).permit(
    :name, :passport_country, :current_location, :budget_min, :budget_max,
    :length_of_stay, :travel_style, :travel_month, :trip_scope, :trip_type,
    :general_purpose, :start_date, :end_date, :safety_preference  # ✅ New parameter
  )
end
```

## Verification

Database queries are working correctly:

| Safety Level | Countries | GPI Range |
|-------------|-----------|-----------|
| Very Safe | 27 | 1.095 - 1.593 |
| Generally Safe | 79 | 1.609 - 2.149 |
| Partly Safe | 34 | 2.157 - 2.695 |
| Not Safe | 23 | 2.731 - 3.441 |

## Expected Behavior After Fix

1. **User selects "Level 4 - Extreme Risk"**
   - Form submits: `safety_preference = "Not Safe"`
   - Controller permits this parameter ✅
   - Service queries: `CountrySafetyScore.not_safe` (GPI ≥ 2.7)
   - Returns: 23 countries (Cameroon, Ethiopia, Venezuela, Colombia, etc.)
   - LLM generates recommendations ONLY from those 23 countries

2. **User selects "Level 1 - Safe Destinations"**
   - Form submits: `safety_preference = "Very Safe"`
   - Service queries: `CountrySafetyScore.very_safe` (GPI < 1.6)
   - Returns: 27 countries (Iceland, Ireland, New Zealand, Japan, etc.)
   - LLM generates recommendations ONLY from those 27 countries

## Files Modified
- `app/controllers/travel_recommendations_controller.rb` - Fixed `travel_plan_params` method

## Testing
1. Refresh the page
2. Select "Level 4 - Extreme Risk"
3. Submit the form
4. ✅ Should now get recommendations from high-risk countries (GPI ≥ 2.7) only
5. Try other levels to verify filtering works correctly
