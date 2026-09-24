import { Controller } from "@hotwired/stimulus"

// Auto-submits the employee roster's search/filter form: immediately when a
// dropdown changes, debounced while typing in the search box.
export default class extends Controller {
  static targets = ["search"]

  submit() {
    this.element.requestSubmit()
  }

  debouncedSubmit() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.submit(), 350)
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
  }
}
