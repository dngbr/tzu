import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  
  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.hideOnClickOutside.bind(this))
  }
  
  disconnect() {
    document.removeEventListener("click", this.hideOnClickOutside.bind(this))
  }
  
  toggle() {
    this.element.classList.toggle("hidden")
  }
  
  hide() {
    this.element.classList.add("hidden")
  }
  
  hideOnClickOutside(event) {
    // Don't close if clicking inside the dropdown or on the bell
    const bellButton = document.querySelector('#notification-bell button')
    
    if (bellButton && bellButton.contains(event.target)) {
      return
    }
    
    if (this.element.contains(event.target)) {
      return
    }
    
    this.hide()
  }
}
