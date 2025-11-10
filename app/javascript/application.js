// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

// Function to initialize Bootstrap dropdowns
function initializeDropdowns() {
  // Wait for Bootstrap to be loaded
  if (typeof bootstrap === 'undefined' || !bootstrap.Dropdown) {
    return;
  }

  const dropdownElementList = document.querySelectorAll('[data-bs-toggle="dropdown"]');
  dropdownElementList.forEach(function(dropdownToggleEl) {
    // Dispose existing dropdown instance if it exists to avoid conflicts
    const existingDropdown = bootstrap.Dropdown.getInstance(dropdownToggleEl);
    if (existingDropdown) {
      existingDropdown.dispose();
    }
    // Create new dropdown instance
    new bootstrap.Dropdown(dropdownToggleEl);
  });
}

// Initialize Bootstrap dropdowns after Turbo navigation
document.addEventListener("turbo:load", function() {
  initializeDropdowns();
});

// Also initialize after Turbo frame loads
document.addEventListener("turbo:frame-load", function() {
  initializeDropdowns();
});

// Initialize on DOMContentLoaded as a fallback
document.addEventListener("DOMContentLoaded", function() {
  initializeDropdowns();
});

// Like/Dislike Recommendation Feedback
document.addEventListener('turbo:load', function() {
  // Get CSRF token
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  
  // Helper function to escape HTML
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
  
  // Handle Like button clicks
  document.querySelectorAll('.like-btn').forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      submitFeedback(this, 'like');
    });
  });
  
  // Handle Dislike button clicks
  document.querySelectorAll('.dislike-btn').forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      submitFeedback(this, 'dislike');
    });
  });
  
  function submitFeedback(button, feedbackType) {
    // Get the button group (contains both like and dislike buttons)
    const buttonGroup = button.closest('.btn-group');
    const likeBtn = buttonGroup.querySelector('.like-btn');
    const dislikeBtn = buttonGroup.querySelector('.dislike-btn');
    
    // Check if already in this state - if so, remove the feedback
    const isAlreadyActive = button.classList.contains(feedbackType === 'like' ? 'btn-success' : 'btn-danger');
    
    if (isAlreadyActive) {
      // User is un-liking or un-disliking - remove feedback
      removeFeedback(button, feedbackType, likeBtn, dislikeBtn);
      return;
    }
    
    // Get data from button attributes
    const data = {
      feedback_type: feedbackType,
      destination_city: button.dataset.city,
      destination_country: button.dataset.country,
      trip_type: button.dataset.tripType,
      travel_style: button.dataset.travelStyle,
      budget_min: parseInt(button.dataset.budgetMin) || 0,
      budget_max: parseInt(button.dataset.budgetMax) || 0,
      length_of_stay: parseInt(button.dataset.lengthOfStay) || 0
    };
    
    // Disable both buttons during request
    likeBtn.disabled = true;
    dislikeBtn.disabled = true;
    const originalText = button.innerHTML;
    button.innerHTML = feedbackType === 'like' ? '❤️ Saving...' : '👎 Saving...';
    
    // Submit feedback
    fetch('/recommendation_feedbacks', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify(data)
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      return response.json();
    })
    .then(result => {
      // Reset both buttons first
      resetButton(likeBtn);
      resetButton(dislikeBtn);
      
      // Update the clicked button appearance
      if (feedbackType === 'like') {
        likeBtn.classList.remove('btn-outline-success');
        likeBtn.classList.add('btn-success');
        likeBtn.innerHTML = '❤️ Liked!';
      } else {
        dislikeBtn.classList.remove('btn-outline-danger');
        dislikeBtn.classList.add('btn-danger');
        dislikeBtn.innerHTML = '👎 Disliked!';
      }
      
      // Re-enable buttons
      likeBtn.disabled = false;
      dislikeBtn.disabled = false;
      
      // Show success message
      showMessage('Feedback saved! This will improve future recommendations.', 'success');
    })
    .catch(error => {
      console.error('Error saving feedback:', error);
      button.innerHTML = originalText;
      likeBtn.disabled = false;
      dislikeBtn.disabled = false;
      showMessage('Failed to save feedback. Please try again.', 'danger');
    });
  }
  
  function resetButton(button) {
    // Reset button to default state
    if (button.classList.contains('like-btn')) {
      button.classList.remove('btn-success');
      button.classList.add('btn-outline-success');
      button.innerHTML = '❤️ Like';
    } else {
      button.classList.remove('btn-danger');
      button.classList.add('btn-outline-danger');
      button.innerHTML = '👎 Dislike';
    }
  }
  
  function removeFeedback(button, feedbackType, likeBtn, dislikeBtn) {
    // Disable both buttons during request
    likeBtn.disabled = true;
    dislikeBtn.disabled = true;
    button.innerHTML = feedbackType === 'like' ? '❤️ Removing...' : '👎 Removing...';
    
    // Get the feedback ID from data attribute (we'll need to add this when creating feedback)
    const data = {
      destination_city: button.dataset.city,
      destination_country: button.dataset.country,
      feedback_type: feedbackType
    };
    
    // Find and delete the feedback
    fetch('/recommendation_feedbacks/remove', {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify(data)
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      return response.json();
    })
    .then(result => {
      // Reset button to default state
      resetButton(button);
      likeBtn.disabled = false;
      dislikeBtn.disabled = false;
      showMessage('Feedback removed.', 'info');
    })
    .catch(error => {
      console.error('Error removing feedback:', error);
      likeBtn.disabled = false;
      dislikeBtn.disabled = false;
      showMessage('Failed to remove feedback. Please try again.', 'danger');
    });
  }
  
  function showMessage(message, type) {
    // Create alert element
    const alert = document.createElement('div');
    alert.className = `alert alert-${type} alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3`;
    alert.style.zIndex = '9999';
    alert.innerHTML = `
      ${escapeHtml(message)}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(alert);
    
    // Auto-dismiss after 3 seconds
    setTimeout(() => {
      alert.classList.remove('show');
      setTimeout(() => alert.remove(), 150);
    }, 3000);
  }
});
