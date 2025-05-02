import consumer from "./consumer"

// This connects to the NotificationChannel on the server
consumer.subscriptions.create("NotificationChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("Connected to NotificationChannel")
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log("Disconnected from NotificationChannel")
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log("Received notification:", data)
    
    // Dispatch a custom event that our toast controller can listen for
    const event = new CustomEvent('notification:received', { detail: data })
    document.dispatchEvent(event)
  }
});
