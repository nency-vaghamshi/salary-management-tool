import { Controller } from "@hotwired/stimulus"

// Dismissible flash message. Success notices fade out on their own; alerts
// stay until dismissed so an error is never missed.
export default class extends Controller {
  static values = { autohide: Boolean }

  connect() {
    if (this.autohideValue) this.timer = setTimeout(() => this.dismiss(), 6000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.classList.add("opacity-0")
    setTimeout(() => this.element.remove(), 200)
  }
}
