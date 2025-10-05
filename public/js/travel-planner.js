// Travel Planner Frontend JavaScript

class TravelPlannerAPI {
  constructor(baseURL = 'http://localhost:3000/api/v1') {
    this.baseURL = baseURL;
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const config = {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      ...options,
    };

    try {
      const response = await fetch(url, config);
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.message || 'API request failed');
      }
      
      return data;
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  }

  // Users API
  async getUsers() {
    return this.request('/users');
  }

  async getUser(id) {
    return this.request(`/users/${id}`);
  }

  async createUser(userData) {
    return this.request('/users', {
      method: 'POST',
      body: JSON.stringify({ user: userData }),
    });
  }

  async updateUser(id, userData) {
    return this.request(`/users/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ user: userData }),
    });
  }

  async deleteUser(id) {
    return this.request(`/users/${id}`, {
      method: 'DELETE',
    });
  }

  // Destinations API
  async getDestinations(filters = {}) {
    const params = new URLSearchParams(filters);
    const query = params.toString() ? `?${params.toString()}` : '';
    return this.request(`/destinations${query}`);
  }

  async getDestination(id) {
    return this.request(`/destinations/${id}`);
  }

  async createDestination(destinationData) {
    return this.request('/destinations', {
      method: 'POST',
      body: JSON.stringify({ destination: destinationData }),
    });
  }

  // Travel Plans API
  async getTravelPlans(userId = null) {
    const query = userId ? `?user_id=${userId}` : '';
    return this.request(`/travel_plans${query}`);
  }

  async createTravelPlan(planData) {
    return this.request('/travel_plans', {
      method: 'POST',
      body: JSON.stringify({ travel_plan: planData }),
    });
  }

  // Travel Recommendations API
  async getRecommendations(userId = null) {
    const query = userId ? `?user_id=${userId}` : '';
    return this.request(`/travel_recommendations${query}`);
  }

  async generateRecommendations(userId) {
    return this.request('/travel_recommendations', {
      method: 'POST',
      body: JSON.stringify({ user_id: userId }),
    });
  }
}

// UI Helper Functions
class TravelPlannerUI {
  constructor() {
    this.api = new TravelPlannerAPI();
    this.init();
  }

  init() {
    this.setupEventListeners();
    this.loadInitialData();
  }

  setupEventListeners() {
    // User form submission
    const userForm = document.getElementById('user-form');
    if (userForm) {
      userForm.addEventListener('submit', (e) => this.handleUserSubmit(e));
    }

    // Get recommendations button
    const getRecommendationsBtn = document.getElementById('get-recommendations');
    if (getRecommendationsBtn) {
      getRecommendationsBtn.addEventListener('click', (e) => this.handleGetRecommendations(e));
    }

    // Load destinations button
    const loadDestinationsBtn = document.getElementById('load-destinations');
    if (loadDestinationsBtn) {
      loadDestinationsBtn.addEventListener('click', () => this.loadDestinations());
    }
  }

  async loadInitialData() {
    try {
      await this.loadUsers();
      await this.loadDestinations();
    } catch (error) {
      this.showError('Failed to load initial data: ' + error.message);
    }
  }

  async loadUsers() {
    try {
      const response = await this.api.getUsers();
      this.renderUsers(response.data);
    } catch (error) {
      console.error('Failed to load users:', error);
    }
  }

  async loadDestinations() {
    try {
      const response = await this.api.getDestinations();
      this.renderDestinations(response.data);
    } catch (error) {
      console.error('Failed to load destinations:', error);
    }
  }

  async handleUserSubmit(e) {
    e.preventDefault();
    const formData = new FormData(e.target);
    const userData = Object.fromEntries(formData.entries());
    
    // Convert numeric fields
    userData.budget_min = parseFloat(userData.budget_min) || 0;
    userData.budget_max = parseFloat(userData.budget_max) || 0;
    userData.safety_preference = parseInt(userData.safety_preference) || 5;

    try {
      const response = await this.api.createUser(userData);
      this.showSuccess('User created successfully!');
      e.target.reset();
      await this.loadUsers();
    } catch (error) {
      this.showError('Failed to create user: ' + error.message);
    }
  }

  async handleGetRecommendations(e) {
    const userId = document.getElementById('user-select')?.value;
    if (!userId) {
      this.showError('Please select a user first');
      return;
    }

    try {
      this.showLoading('Generating recommendations...');
      const response = await this.api.generateRecommendations(userId);
      this.renderRecommendations(response.data);
      this.hideLoading();
      this.showSuccess('Recommendations generated!');
    } catch (error) {
      this.hideLoading();
      this.showError('Failed to generate recommendations: ' + error.message);
    }
  }

  renderUsers(users) {
    const container = document.getElementById('users-list');
    const select = document.getElementById('user-select');
    
    if (container) {
      container.innerHTML = users.map(user => `
        <div class="user-card">
          <h4>${user.name}</h4>
          <p>Email: ${user.email}</p>
          <p>Passport: ${user.passport_country}</p>
          <p>Budget: $${user.budget_min} - $${user.budget_max}</p>
          <p>Safety Preference: ${user.safety_preference}/10</p>
        </div>
      `).join('');
    }

    if (select) {
      select.innerHTML = '<option value="">Select a user...</option>' + 
        users.map(user => `<option value="${user.id}">${user.name}</option>`).join('');
    }
  }

  renderDestinations(destinations) {
    const container = document.getElementById('destinations-list');
    if (container) {
      container.innerHTML = destinations.map(dest => `
        <div class="destination-card">
          <h4>${dest.name}, ${dest.country}</h4>
          <p>${dest.description}</p>
          <p>Safety Score: ${dest.safety_score}/10</p>
          <p>Average Cost: $${dest.average_cost}</p>
          <p>Best Season: ${dest.best_season}</p>
          <p>Visa Required: ${dest.visa_required ? 'Yes' : 'No'}</p>
        </div>
      `).join('');
    }
  }

  renderRecommendations(recommendations) {
    const container = document.getElementById('recommendations-list');
    if (container) {
      container.innerHTML = recommendations.map(rec => `
        <div class="recommendation-card">
          <h4>${rec.destination.name}, ${rec.destination.country}</h4>
          <p class="score">Recommendation Score: ${rec.recommendation_score}/10</p>
          <p>${rec.destination.description}</p>
          <p class="reasons"><strong>Why this destination:</strong> ${rec.reasons}</p>
          <div class="destination-details">
            <span>Safety: ${rec.destination.safety_score}/10</span>
            <span>Cost: $${rec.destination.average_cost}</span>
            <span>Season: ${rec.destination.best_season}</span>
          </div>
        </div>
      `).join('');
    }
  }

  showSuccess(message) {
    this.showAlert(message, 'success');
  }

  showError(message) {
    this.showAlert(message, 'error');
  }

  showAlert(message, type) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type}`;
    alertDiv.textContent = message;
    
    const container = document.querySelector('.alerts-container') || document.body;
    container.appendChild(alertDiv);
    
    setTimeout(() => {
      alertDiv.remove();
    }, 5000);
  }

  showLoading(message) {
    const loadingDiv = document.getElementById('loading');
    if (loadingDiv) {
      loadingDiv.textContent = message;
      loadingDiv.style.display = 'block';
    }
  }

  hideLoading() {
    const loadingDiv = document.getElementById('loading');
    if (loadingDiv) {
      loadingDiv.style.display = 'none';
    }
  }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  window.travelPlanner = new TravelPlannerUI();
});