import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async perform() {
    const token = localStorage.getItem("jwt")

    await fetch("/api/v1/auth/logout", {
      method: "DELETE",
      headers: token ? { "Authorization": `Bearer ${token}` } : {}
    })

    localStorage.removeItem("jwt")
    Turbo.visit("/login")
  }
}
