import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]
  
  connect() {
    console.log("Sidebar notifications controller connected")
    // Close dropdown when clicking outside
    document.addEventListener("click", this.closeDropdown.bind(this))
  }
  
  disconnect() {
    document.removeEventListener("click", this.closeDropdown.bind(this))
  }
  
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    console.log("Toggle clicked", this.dropdownTarget)
    this.dropdownTarget.classList.toggle("hidden")
    
    if (!this.dropdownTarget.classList.contains("hidden")) {
      this.positionDropdown()
    }
  }
  
  closeDropdown(event) {
    if (!this.element.contains(event.target) && !this.dropdownTarget.classList.contains("hidden")) {
      this.dropdownTarget.classList.add("hidden")
    }
  }
  
  positionDropdown() {
    const button = this.element.querySelector('button')
    const dropdown = this.dropdownTarget
    const buttonRect = button.getBoundingClientRect()
    
    // Position to the right of the sidebar
    dropdown.style.top = `${buttonRect.top}px`
  }
}
