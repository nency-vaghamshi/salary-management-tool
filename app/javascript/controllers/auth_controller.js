import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "password", "error", "submit", "spinner", "submitLabel"]

  async submit(event) {
    event.preventDefault()
    this.errorTarget.classList.add("hidden")
    this.setLoading(true)

    try {
      const response = await fetch("/users/sign_in", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json" },
        body: JSON.stringify({
          user: { email: this.emailTarget.value, password: this.passwordTarget.value }
        })
      })

      if (!response.ok) {
        this.errorTarget.classList.remove("hidden")
        return
      }

      // The server has set the HttpOnly auth cookie; nothing to store client-side.
      Turbo.visit("/")
    } finally {
      this.setLoading(false)
    }
  }

  setLoading(isLoading) {
    this.submitTarget.disabled = isLoading
    this.spinnerTarget.classList.toggle("hidden", !isLoading)
    this.submitLabelTarget.textContent = isLoading ? "Signing in..." : "Sign in"
  }
}
