import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  markAsRead() {
    const id = this.element.dataset.notificationId
    
    fetch(`/my_account/notifications/${id}/mark_as_read`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json'
      },
      credentials: 'same-origin'
    })
    .then(response => {
      if (response.ok) {
        // Update UI to show notification as read
        this.element.classList.remove('bg-blue-50')
        this.element.classList.add('bg-white')
        
        // Update unread count badge if present
        const badge = document.querySelector('.notifications-badge')
        if (badge) {
          const count = parseInt(badge.textContent) - 1
          if (count <= 0) {
            badge.classList.add('hidden')
          } else {
            badge.textContent = count
          }
        }
      }
    })
  }
}
