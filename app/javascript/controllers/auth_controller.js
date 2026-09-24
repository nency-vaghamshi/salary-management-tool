import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "password", "error", "submit", "spinner", "submitLabel"]

  async submit(event) {
    event.preventDefault()
    this.errorTarget.classList.add("hidden")
    this.setLoading(true)

    try {
      const response = await fetch("/api/v1/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json" },
        body: JSON.stringify({
          email: this.emailTarget.value,
          password: this.passwordTarget.value
        })
      })

      if (!response.ok) {
        this.errorTarget.classList.remove("hidden")
        return
      }

      const data = await response.json()
      localStorage.setItem("jwt", data.token)
      Turbo.visit("/employees")
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
