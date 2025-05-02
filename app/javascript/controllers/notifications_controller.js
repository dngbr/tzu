import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]
  
  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.hideOnClickOutside.bind(this))
  }
  
  disconnect() {
    document.removeEventListener("click", this.hideOnClickOutside.bind(this))
  }
  
  toggle(event) {
    event.stopPropagation()
    
    // Toggle visibility
    const isHidden = this.dropdownTarget.classList.toggle("hidden")
    
    // If now visible, position the dropdown relative to the bell
    if (!isHidden) {
      this.positionDropdown()
    }
  }
  
  positionDropdown() {
    const bell = this.element.querySelector('a')
    const dropdown = this.dropdownTarget
    
    if (bell && dropdown) {
      const bellRect = bell.getBoundingClientRect()
      const rightOffset = window.innerWidth - bellRect.right
      
      // Position dropdown below the bell and aligned with its right edge
      dropdown.style.top = `${bellRect.bottom + 10}px`
      dropdown.style.right = `${rightOffset}px`
    }
  }
  
  hideOnClickOutside(event) {
    // Don't close if clicking inside the controller element
    if (this.element.contains(event.target)) {
      return
    }
    
    // Close the dropdown
    this.dropdownTarget.classList.add("hidden")
  }
}
