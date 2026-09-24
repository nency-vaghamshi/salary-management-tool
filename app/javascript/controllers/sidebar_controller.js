import { Controller } from "@hotwired/stimulus"

// Mobile navigation drawer. On lg+ screens the sidebar is always visible via
// CSS, so this only ever toggles the small-screen state.
export default class extends Controller {
  static targets = ["panel", "backdrop", "toggle"]

  open() {
    this.panelTarget.classList.remove("-translate-x-full")
    this.backdropTarget.classList.remove("hidden")
    this.toggleTargets.forEach((button) => button.setAttribute("aria-expanded", "true"))
    this.panelTarget.querySelector("a")?.focus()
  }

  close() {
    this.panelTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
    this.toggleTargets.forEach((button) => button.setAttribute("aria-expanded", "false"))
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
