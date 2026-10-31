// An expired or revoked cookie token surfaces as a 401 on Turbo fetches; send the user to sign in.
document.addEventListener("turbo:before-fetch-response", (event) => {
  if (event.detail.fetchResponse.response.status === 401) {
    Turbo.visit("/users/sign_in")
  }
})
