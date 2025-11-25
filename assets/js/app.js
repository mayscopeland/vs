// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Player Modal Functions - using event delegation for reliability
function openPlayerModal(button) {
  const playerId = button.dataset.playerId
  const leagueId = button.dataset.leagueId

  if (!playerId || !leagueId) {
    console.error('Missing player_id or league_id')
    return
  }

  // Show modal immediately with loading spinner
  const modal = document.getElementById('player-modal')
  const modalContent = document.getElementById('player-modal-content')
  const bg = document.getElementById('player-modal-bg')
  const container = document.getElementById('player-modal-container')

  if (modalContent) {
    modalContent.innerHTML = `
      <div class="p-12 flex items-center justify-center">
        <div class="flex flex-col items-center gap-3">
          <svg class="animate-spin h-8 w-8 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span class="text-sm text-gray-500">Loading player...</span>
        </div>
      </div>
    `
  }

  if (modal) {
    modal.classList.remove('hidden')
    setTimeout(() => {
      if (bg) bg.classList.add('opacity-100')
      if (container) {
        container.classList.remove('hidden')
        container.classList.add('opacity-100', 'translate-y-0', 'sm:scale-100')
      }
    }, 10)
    document.body.classList.add('overflow-hidden')
  }

  // Get current stat source from URL if on player list page
  const urlParams = new URLSearchParams(window.location.search)
  const statSource = urlParams.get('stat_source') || ''

  // Build URL with stat_source if present
  let url = `/leagues/${leagueId}/players/${playerId}`
  if (statSource) {
    url += `?stat_source=${statSource}`
  }

  // Fetch player data and replace loading spinner with content
  fetch(url)
    .then(response => response.text())
    .then(html => {
      if (modalContent) {
        modalContent.innerHTML = html
      }
    })
    .catch(error => {
      console.error('Error fetching player data:', error)
      if (modalContent) {
        modalContent.innerHTML = `
          <div class="p-12 flex items-center justify-center">
            <div class="text-red-600 text-sm">Failed to load player data</div>
          </div>
        `
      }
    })
}

// Event delegation for player modal triggers - works even when DOM is updated
document.addEventListener('click', function(e) {
  const trigger = e.target.closest('.player-modal-trigger')
  if (trigger) {
    e.preventDefault()
    openPlayerModal(trigger)
    return
  }

  // Handle close modal clicks
  const closeBtn = e.target.closest('.player-modal-close')
  if (closeBtn) {
    closePlayerModal()
  }
})

function closePlayerModal() {
  const modal = document.getElementById('player-modal')
  if (!modal || modal.classList.contains('hidden')) return

  const bg = document.getElementById('player-modal-bg')
  const container = document.getElementById('player-modal-container')

  if (bg) bg.classList.remove('opacity-100')
  if (container) {
    container.classList.remove('opacity-100', 'translate-y-0', 'sm:scale-100')
    container.classList.add('opacity-0', 'translate-y-4', 'sm:translate-y-0', 'sm:scale-95')
  }

  setTimeout(() => {
    if (modal) modal.classList.add('hidden')
    if (container) container.classList.add('hidden')
    document.body.classList.remove('overflow-hidden')
  }, 200)
}

// Close modal on escape key
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    closePlayerModal()
  }
})
