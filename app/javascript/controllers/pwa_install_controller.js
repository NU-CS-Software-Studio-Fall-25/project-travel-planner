// PWA Install Prompt Controller
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]
  
  connect() {
    // Check if already installed
    if (this.isPWA()) {
      return
    }

    // Listen for beforeinstallprompt event
    window.addEventListener('beforeinstallprompt', (e) => {
      // Prevent the mini-infobar from appearing on mobile
      e.preventDefault()
      // Stash the event so it can be triggered later
      this.deferredPrompt = e
      // Show install banner
      this.showInstallBanner()
    })

    // Check if app was successfully installed
    window.addEventListener('appinstalled', () => {
      console.log('PWA installed successfully!')
      this.hideInstallBanner()
      this.deferredPrompt = null
    })
  }

  showInstallBanner() {
    // Check if user previously dismissed the banner
    if (localStorage.getItem('pwa-install-dismissed') === 'true') {
      return
    }

    const banner = document.createElement('div')
    banner.className = 'pwa-install-banner position-fixed bottom-0 start-0 end-0 bg-primary text-white p-3 shadow-lg'
    banner.style.zIndex = '9999'
    banner.innerHTML = `
      <div class="container d-flex align-items-center justify-content-between flex-wrap">
        <div class="d-flex align-items-center mb-2 mb-md-0">
          <span class="me-2" style="font-size: 2rem;">📱</span>
          <div>
            <strong>Install Travel Planner</strong>
            <p class="mb-0 small">Get quick access and work offline!</p>
          </div>
        </div>
        <div class="d-flex gap-2">
          <button class="btn btn-light btn-sm" data-action="click->pwa-install#install">Install</button>
          <button class="btn btn-outline-light btn-sm" data-action="click->pwa-install#dismiss">Not now</button>
        </div>
      </div>
    `
    banner.dataset.controller = 'pwa-install'
    document.body.appendChild(banner)
    this.bannerElement = banner
  }

  hideInstallBanner() {
    if (this.bannerElement) {
      this.bannerElement.remove()
    }
  }

  async install(event) {
    event.preventDefault()
    
    if (!this.deferredPrompt) {
      return
    }

    // Show the install prompt
    this.deferredPrompt.prompt()
    
    // Wait for the user to respond to the prompt
    const { outcome } = await this.deferredPrompt.userChoice
    
    console.log(`User response to install prompt: ${outcome}`)
    
    // Clear the deferredPrompt
    this.deferredPrompt = null
    
    // Hide the banner
    this.hideInstallBanner()
  }

  dismiss(event) {
    event.preventDefault()
    localStorage.setItem('pwa-install-dismissed', 'true')
    this.hideInstallBanner()
  }

  isPWA() {
    return window.matchMedia('(display-mode: standalone)').matches || 
           window.navigator.standalone === true ||
           document.referrer.includes('android-app://')
  }
}
