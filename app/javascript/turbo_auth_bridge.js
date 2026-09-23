document.addEventListener("turbo:before-fetch-request", (event) => {
  const token = localStorage.getItem("jwt")
  if (!token) return

  event.detail.fetchOptions.headers["Authorization"] = `Bearer ${token}`
})

document.addEventListener("turbo:before-fetch-response", async (event) => {
  if (event.detail.fetchResponse.response.status === 401) {
    localStorage.removeItem("jwt")
    Turbo.visit("/login")
  }
})
