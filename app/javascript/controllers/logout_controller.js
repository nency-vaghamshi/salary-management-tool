import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async perform() {
    // The browser sends the HttpOnly auth cookie itself; the server revokes the token and clears it.
    await fetch("/users/sign_out", {
      method: "DELETE",
      headers: { "Accept": "application/json" }
    })

    Turbo.visit("/users/sign_in")
  }
}
