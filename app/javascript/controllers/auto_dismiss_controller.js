// app/javascript/controllers/auto_dismiss_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.delayValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // Use Bootstrap's alert dismiss functionality
    const alert = this.element.querySelector('.alert')
    if (alert) {
      const bsAlert = bootstrap.Alert.getOrCreateInstance(alert)
      bsAlert.close()
    }
    // Fallback: just remove the element
    this.element.remove()
  }
}
