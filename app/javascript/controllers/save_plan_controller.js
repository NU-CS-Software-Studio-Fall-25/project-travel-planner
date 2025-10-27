// app/javascript/controllers/save_plan_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  save(event) {
    const button = event.target.closest('button')
    if (button) {
      // Disable the button and show it's been saved
      button.disabled = true
      button.classList.remove('btn-primary')
      button.classList.add('btn-success')
      button.innerHTML = '✓ Saved'
    }
  }
}
