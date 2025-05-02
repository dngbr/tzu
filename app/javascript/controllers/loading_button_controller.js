import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "spinner", "text"]
  
  connect() {
    // Make sure the spinner is hidden initially
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
  }
  
  startLoading(event) {
    // Show spinner
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }
    
    // Hide or change text if needed
    if (this.hasTextTarget) {
      this.textTarget.textContent = this.textTarget.getAttribute("data-loading-text") || "Processing..."
    }
    
    // Disable the button to prevent multiple clicks
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.classList.add("opacity-75", "cursor-not-allowed")
    }
  }
}
