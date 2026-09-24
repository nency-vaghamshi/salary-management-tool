import { Controller } from "@hotwired/stimulus"

// "Download PDF": opens the browser's print dialog, where Save as PDF is the
// destination. The page's print styles strip the app chrome.
export default class extends Controller {
  print() {
    window.print()
  }
}
