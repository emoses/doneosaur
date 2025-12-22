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
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/doneosaur"
import topbar from "../vendor/topbar"

// Client storage hook for persisting client name
const ClientStorage = {
  mounted() {
    const clientName = localStorage.getItem("doneosaur_client_name")
    if (clientName) {
      this.pushEvent("client_name_loaded", {name: clientName})
    }
  },
  updated() {
    const clientName = this.el.dataset.clientName
    if (clientName) {
      localStorage.setItem("doneosaur_client_name", clientName)
    }
  }
}

// Drag-and-drop hook for reordering task list items in admin
const DragDropTaskList = {
  mounted() {
    this.handlers = []
    this.initDragDrop()
  },
  updated() {
    this.cleanupDragDrop()
    this.initDragDrop()
  },
  destroyed() {
    this.cleanupDragDrop()
  },
  cleanupDragDrop() {
    // Remove all event listeners
    this.handlers.forEach(({element, event, handler}) => {
      element.removeEventListener(event, handler)
    })
    this.handlers = []
  },
  initDragDrop() {
    const container = this.el
    const items = container.querySelectorAll('.task-list-item')

    items.forEach((item) => {
      item.setAttribute('draggable', 'true')
      const index = parseInt(item.dataset.index)

      const dragstartHandler = (e) => {
        item.classList.add('dragging')
        e.dataTransfer.effectAllowed = 'move'
        e.dataTransfer.setData('text/plain', index)
      }
      item.addEventListener('dragstart', dragstartHandler)
      this.handlers.push({element: item, event: 'dragstart', handler: dragstartHandler})

      const dragendHandler = (e) => {
        item.classList.remove('dragging')
        items.forEach(i => {
          i.classList.remove('drag-over-top')
          i.classList.remove('drag-over-bottom')
        })
      }
      item.addEventListener('dragend', dragendHandler)
      this.handlers.push({element: item, event: 'dragend', handler: dragendHandler})

      const dragoverHandler = (e) => {
        e.preventDefault()
        e.dataTransfer.dropEffect = 'move'

        const dragging = container.querySelector('.dragging')
        if (dragging && dragging !== item) {
          // Determine if mouse is in top half or bottom half of item
          const rect = item.getBoundingClientRect()
          const midpoint = rect.top + rect.height / 2
          const isTopHalf = e.clientY < midpoint

          // Clear both classes first
          item.classList.remove('drag-over-top', 'drag-over-bottom')

          // Add appropriate class based on position
          if (isTopHalf) {
            item.classList.add('drag-over-top')
          } else {
            item.classList.add('drag-over-bottom')
          }
        }
      }
      item.addEventListener('dragover', dragoverHandler)
      this.handlers.push({element: item, event: 'dragover', handler: dragoverHandler})

      const dragleaveHandler = (e) => {
        item.classList.remove('drag-over-top', 'drag-over-bottom')
      }
      item.addEventListener('dragleave', dragleaveHandler)
      this.handlers.push({element: item, event: 'dragleave', handler: dragleaveHandler})

      const dropHandler = (e) => {
        e.preventDefault()
        e.stopPropagation()
        item.classList.remove('drag-over-top', 'drag-over-bottom')

        const fromIndex = parseInt(e.dataTransfer.getData('text/plain'))
        const targetIndex = parseInt(item.dataset.index)

        // Determine if drop is in top half or bottom half
        const rect = item.getBoundingClientRect()
        const midpoint = rect.top + rect.height / 2
        const isTopHalf = e.clientY < midpoint

        // Calculate gap index (0 to n, where n is number of items)
        // Top half of item i means gap i (before item i)
        // Bottom half of item i means gap i+1 (after item i)
        const toGap = isTopHalf ? targetIndex : targetIndex + 1

        this.pushEvent('reorder_task', {from: fromIndex, to: toGap})
      }
      item.addEventListener('drop', dropHandler)
      this.handlers.push({element: item, event: 'drop', handler: dropHandler})
    })
  }
}

// Dialog handlers
window.addEventListener("hide-dialog", event => event.target?.close())
window.addEventListener("show-dialog", event => event.target?.showModal())


const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ClientStorage, DragDropTaskList},
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

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
