import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "email", "password", "passwordConfirmation", "error", "submit", "spinner", "submitLabel"]

  async submit(event) {
    event.preventDefault()
    this.errorTarget.classList.add("hidden")
    this.setLoading(true)

    try {
      const response = await fetch("/users", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json" },
        body: JSON.stringify({
          user: {
            name: this.nameTarget.value,
            email: this.emailTarget.value,
            password: this.passwordTarget.value,
            password_confirmation: this.passwordConfirmationTarget.value
          }
        })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showErrors([data.status?.message || "Something went wrong. Please try again."])
        return
      }

      Turbo.visit("/")
    } finally {
      this.setLoading(false)
    }
  }

  showErrors(messages) {
    this.errorTarget.replaceChildren(
      ...messages.map((message) => {
        const item = document.createElement("li")
        item.textContent = message
        return item
      })
    )
    this.errorTarget.classList.remove("hidden")
  }

  setLoading(isLoading) {
    this.submitTarget.disabled = isLoading
    this.spinnerTarget.classList.toggle("hidden", !isLoading)
    this.submitLabelTarget.textContent = isLoading ? "Creating account..." : "Create account"
  }
}
