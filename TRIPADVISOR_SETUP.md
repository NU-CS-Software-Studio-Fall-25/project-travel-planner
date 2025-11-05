# TripAdvisor API Integration Guide

## Overview
This app now integrates with TripAdvisor API to display location images for recommended destinations.

## Setup Instructions

### 1. API Key Configuration
The TripAdvisor API key is configured in `.env`:
```
TRIPADVISOR_API_KEY=BD9366999C904AA496AA71854FCD2EA5
```

### 2. Domain Restrictions
TripAdvisor API requires domain whitelisting. Currently configured domains:
- `travel-planner-cs397-9396d2cb2102.herokuapp.com` (production)
- `lvh.me` (local development alternative)
- `127.0.0.1.nip.io` (local development)

### 3. Local Development Access

**IMPORTANT**: To use TripAdvisor API locally, you MUST access your app through one of the whitelisted domains:

#### Option 1: Using 127.0.0.1.nip.io (Recommended)
```bash
rails s
# Then visit: http://127.0.0.1.nip.io:3000
```

#### Option 2: Using lvh.me
```bash
rails s
# Then visit: http://lvh.me:3000
```

**DO NOT use `http://localhost:3000`** - it will cause 403 errors!

### 4. How It Works

1. **Client-Side API Calls**: The app makes API calls directly from the browser to respect domain restrictions
2. **SessionStorage Caching**: Images are cached in browser sessionStorage to avoid repeated API calls
3. **Persistent Across Navigation**: Cached images remain available even when navigating between pages
4. **No Server Storage**: Images are NOT stored in the database, only cached in browser

### 5. Features

#### Image Gallery
- **Location**: Below "View Detailed Itinerary" button
- **Trigger**: Accordion labeled "Images of the Place"
- **Images**: 3-5 high-quality photos from TripAdvisor
- **Lazy Loading**: Images load only when accordion is opened

#### Accessibility Features
- **Zoom Functionality**: Click any image to view full-size in modal
- **Keyboard Support**: 
  - Tab to navigate through images
  - Enter to open zoomed view
  - Escape to close modal
- **Screen Reader Support**: 
  - All images have descriptive alt text
  - Modal has proper ARIA labels
  - Image captions visible on hover and in modal

#### Performance
- **First Load**: Fetches from TripAdvisor API
- **Subsequent Views**: Loads from sessionStorage cache
- **Across Pages**: Cache persists during browser session
- **Saved Plans**: No images stored, link to TripAdvisor provided

### 6. Testing

To test the integration:

1. Start Rails server:
   ```bash
   rails s
   ```

2. Access via whitelisted domain:
   ```
   http://127.0.0.1.nip.io:3000
   ```

3. Generate travel recommendations

4. Click "Images of the Place" accordion

5. Verify:
   - Images load successfully
   - Click image to zoom
   - Check browser console for any errors
   - Navigate away and back to verify cache works

### 7. Troubleshooting

#### 403 Error: "User is not authorized"
- **Cause**: Accessing app from non-whitelisted domain
- **Solution**: Use `http://127.0.0.1.nip.io:3000` instead of `localhost:3000`

#### No Images Showing
- **Check**: Browser console for API errors
- **Verify**: API key is correctly set in `.env`
- **Test**: Make sure destination_city has valid format (e.g., "Miami, Florida")

#### Images Not Caching
- **Check**: Browser's sessionStorage is enabled
- **Note**: Cache clears when browser tab is closed

### 8. Production Deployment

For Heroku deployment:
1. Set environment variable:
   ```bash
   heroku config:set TRIPADVISOR_API_KEY=BD9366999C904AA496AA71854FCD2EA5
   ```

2. Verify domain is whitelisted on TripAdvisor API portal:
   - `travel-planner-cs397-9396d2cb2102.herokuapp.com`

### 9. API Endpoints Used

- **Search**: `/location/search` - Find location by name
- **Details**: `/location/{id}/details` - Get location info and URL
- **Photos**: `/location/{id}/photos` - Fetch location images

### 10. Future Enhancements

Potential improvements:
- [ ] Store TripAdvisor URLs in database for saved plans
- [ ] Add more images (increase limit)
- [ ] Implement image carousel navigation
- [ ] Add option to share images
- [ ] Cache in localStorage for longer persistence
