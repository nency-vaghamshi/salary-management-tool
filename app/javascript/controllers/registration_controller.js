import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "email", "password", "passwordConfirmation", "error", "submit", "spinner", "submitLabel"]

  async submit(event) {
    event.preventDefault()
    this.errorTarget.classList.add("hidden")
    this.setLoading(true)

    try {
      const response = await fetch("/api/v1/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Accept": "application/json" },
        body: JSON.stringify({
          name: this.nameTarget.value,
          email: this.emailTarget.value,
          password: this.passwordTarget.value,
          password_confirmation: this.passwordConfirmationTarget.value
        })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showErrors(data.errors || ["Something went wrong. Please try again."])
        return
      }

      localStorage.setItem("jwt", data.token)
      Turbo.visit("/dashboard")
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
