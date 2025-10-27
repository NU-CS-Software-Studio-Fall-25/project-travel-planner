import { Controller } from "@hotwired/stimulus"

// A small Stimulus controller that dynamically loads the Google Maps JS API
// and initializes a map for given lat/lng values.
export default class extends Controller {
  static values = { lat: Number, lng: Number }
  static targets = ["map", "fallback"]

  connect() {
    // If coordinates missing, show fallback and stop
    if (!this.hasLatValue || !this.hasLngValue || Number.isNaN(this.latValue) || Number.isNaN(this.lngValue)) {
      this.showFallback()
      return
    }

    // Load Maps script then init
    this.loadGoogleMapsScript().then(() => this.initMap()).catch((err) => {
      console.error("Failed to load Google Maps:", err)
      this.showFallback()
    })
  }

  showFallback() {
    if (this.hasFallbackTarget) this.fallbackTarget.style.display = "block"
    if (this.hasMapTarget) this.mapTarget.style.display = "none"
  }

  loadGoogleMapsScript() {
    // If already loaded, resolve immediately
    if (window.google && window.google.maps) return Promise.resolve()

    // Make sure we only inject once
    if (document.getElementById('google-maps-script')) {
      return new Promise((resolve, reject) => {
        const check = () => {
          if (window.google && window.google.maps) return resolve()
          setTimeout(check, 50)
        }
        check()
      })
    }

    const apiKeyMeta = document.querySelector('meta[name="google-maps-api-key"]')
    const apiKey = apiKeyMeta ? apiKeyMeta.content : null
    if (!apiKey) return Promise.reject(new Error('Google Maps API key not found in meta tag'))

    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.id = 'google-maps-script'
      script.async = true
      script.defer = true
      script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}`
      script.onload = () => resolve()
      script.onerror = (e) => reject(e)
      document.head.appendChild(script)
    })
  }

  initMap() {
    const mapEl = this.hasMapTarget ? this.mapTarget : this.element
    const center = { lat: parseFloat(this.latValue), lng: parseFloat(this.lngValue) }

    this.map = new window.google.maps.Map(mapEl, {
      center,
      zoom: 12,
      streetViewControl: false,
      mapTypeControl: false
    })

    this.marker = new window.google.maps.Marker({
      position: center,
      map: this.map,
      title: this.element.closest('.card')?.querySelector('h2')?.textContent?.trim() || 'Destination'
    })
  }
}
