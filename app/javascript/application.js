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
