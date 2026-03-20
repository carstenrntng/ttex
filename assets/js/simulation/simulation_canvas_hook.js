import {readGridDimensions, computeCanvasMetrics} from "./canvas_transform"
import {createCanvasSurface, resizeSurface, compositeLayers} from "./canvas_surface"
import {projectEntities} from "./entity_projection"
import {drawGrid, drawProjectedEntities} from "./entity_renderers"

const ZOOM_MIN = 0.65
const ZOOM_MAX = 3.5
const ZOOM_STEP = 0.12
const PAN_OVERSCROLL_PX = 48

function iconButton(label) {
  return `<button type=\"button\" data-action=\"${label}\" class=\"rounded-md bg-slate-700/90 px-2 py-1 font-semibold text-slate-100 transition hover:bg-slate-600\">${label}</button>`
}

function clampZoom(value) {
  return Math.max(ZOOM_MIN, Math.min(ZOOM_MAX, value))
}

function normalizeWheelDelta(event) {
  if (event.deltaMode === 1) {
    return event.deltaY * 16
  }

  return event.deltaY
}

function visibleGridRange(transform, size) {
  const rawColStart = (0 - transform.offsetX) / transform.cellWidth
  const rawColEnd = (size - transform.offsetX) / transform.cellWidth
  const rawRowStart = (0 - transform.offsetY) / transform.cellHeight
  const rawRowEnd = (size - transform.offsetY) / transform.cellHeight

  const colStart = Math.max(0, Math.floor(rawColStart))
  const colEnd = Math.min(transform.cols - 1, Math.ceil(rawColEnd) - 1)
  const rowStart = Math.max(0, Math.floor(rawRowStart))
  const rowEnd = Math.min(transform.rows - 1, Math.ceil(rawRowEnd) - 1)

  return {colStart, colEnd, rowStart, rowEnd}
}

export const SimulationCanvas = {
  mounted() {
    this.container = this.el
    this.viewCanvas = this.container.querySelector("#sim-canvas")

    if (!this.viewCanvas) {
      return
    }

    this.surface = createCanvasSurface(this.viewCanvas)
    this.rowsCols = readGridDimensions(this.container)
    this.projection = {fixedEntities: [], crowds: []}
    this.animationFrameId = null
    this.activePointerId = null
    this.showDebugCoordinates = false
    this.zoom = 1
    this.panX = 0
    this.panY = 0
    this.isPanning = false
    this.panStart = {x: 0, y: 0, panX: 0, panY: 0}

    this.hud = document.createElement("div")
    this.hud.className = "pointer-events-none absolute right-3 top-3 rounded-xl bg-slate-900/80 px-3 py-2 text-xs text-slate-100 shadow-lg backdrop-blur-sm"

    this.controls = document.createElement("div")
    this.controls.className = "absolute right-3 top-28 flex items-center gap-2 rounded-xl bg-slate-900/75 p-2 text-xs text-slate-100 shadow-lg backdrop-blur-sm"
    this.controls.innerHTML = [iconButton("-"), iconButton("+"), iconButton("fit"), iconButton("coords")].join("")

    if (window.getComputedStyle(this.container).position === "static") {
      this.container.style.position = "relative"
    }

    this.container.appendChild(this.hud)
    this.container.appendChild(this.controls)

    this.resetView = () => {
      this.zoom = 1
      this.panX = 0
      this.panY = 0
      this.resizeAndRedraw()
    }

    this.resizeAndRedraw = () => {
      const {rows, cols} = this.rowsCols
      const metrics = computeCanvasMetrics(this.container, rows, cols)
      const scaledCellWidth = metrics.cellWidth * this.zoom
      const scaledCellHeight = metrics.cellHeight * this.zoom
      const scaledGridWidth = cols * scaledCellWidth
      const scaledGridHeight = rows * scaledCellHeight

      const maxPanX = Math.max(0, (scaledGridWidth - metrics.size) / 2) + PAN_OVERSCROLL_PX
      const maxPanY = Math.max(0, (scaledGridHeight - metrics.size) / 2) + PAN_OVERSCROLL_PX

      this.panX = Math.max(-maxPanX, Math.min(maxPanX, this.panX))
      this.panY = Math.max(-maxPanY, Math.min(maxPanY, this.panY))

      this.size = metrics.size
      this.transform = {
        rows,
        cols,
        zoom: this.zoom,
        showDebugCoordinates: this.showDebugCoordinates,
        cellWidth: scaledCellWidth,
        cellHeight: scaledCellHeight,
        offsetX: (metrics.size - scaledGridWidth) / 2 + this.panX,
        offsetY: (metrics.size - scaledGridHeight) / 2 + this.panY,
      }

      const visible = visibleGridRange(this.transform, this.size)

      resizeSurface(this.surface, this.size)
      drawGrid(this.surface.gridCtx, this.transform, this.size)
      this.hud.innerHTML = [
        `<div class=\"font-semibold tracking-wide\">Zoom ${this.zoom.toFixed(2)}×</div>`,
        `<div class=\"text-slate-300\">Grid ${cols} × ${rows}</div>`,
        `<div class=\"text-slate-300\">View c:${visible.colStart}-${visible.colEnd} r:${visible.rowStart}-${visible.rowEnd}</div>`,
        `<div class=\"text-slate-300\">Pan ${Math.round(this.panX)}, ${Math.round(this.panY)}</div>`,
        `<div class=\"text-slate-300\">Coords ${this.showDebugCoordinates ? "ON" : "OFF"} (press c)</div>`,
      ].join("")
    }

    this.onWheel = event => {
      event.preventDefault()

      const wheel = normalizeWheelDelta(event)
      const zoomDelta = wheel > 0 ? -ZOOM_STEP : ZOOM_STEP
      this.zoom = clampZoom(this.zoom + zoomDelta)
      this.resizeAndRedraw()
    }

    this.onControlClick = event => {
      const action = event.target?.dataset?.action

      if (!action) {
        return
      }

      if (action === "fit") {
        this.resetView()
        return
      }

      if (action === "coords") {
        this.showDebugCoordinates = !this.showDebugCoordinates
        this.resizeAndRedraw()
        return
      }

      const delta = action === "+" ? ZOOM_STEP : -ZOOM_STEP
      this.zoom = clampZoom(this.zoom + delta)
      this.resizeAndRedraw()
    }

    this.onPointerDown = event => {
      if (event.button !== 0) {
        return
      }

      this.isPanning = true
      this.activePointerId = event.pointerId
      this.panStart = {
        x: event.clientX,
        y: event.clientY,
        panX: this.panX,
        panY: this.panY,
      }

      this.viewCanvas.setPointerCapture?.(event.pointerId)
      this.viewCanvas.style.cursor = "grabbing"
    }

    this.onPointerMove = event => {
      if (!this.isPanning) {
        return
      }

      if (this.activePointerId !== null && event.pointerId !== this.activePointerId) {
        return
      }

      this.panX = this.panStart.panX + (event.clientX - this.panStart.x)
      this.panY = this.panStart.panY + (event.clientY - this.panStart.y)
      this.resizeAndRedraw()
    }

    this.releasePan = () => {
      this.isPanning = false
      this.activePointerId = null
      this.viewCanvas.style.cursor = "grab"
    }

    this.onPointerUp = event => {
      if (this.activePointerId !== null && event.pointerId !== this.activePointerId) {
        return
      }

      this.releasePan()
    }

    this.onPointerCancel = () => {
      this.releasePan()
    }

    this.onWindowBlur = () => {
      this.releasePan()
    }

    this.onVisibilityChange = () => {
      if (document.hidden) {
        this.releasePan()
      }
    }

    this.onDoubleClick = () => {
      this.resetView()
    }

    this.onKeyDown = event => {
      if (event.key.toLowerCase() === "c") {
        this.showDebugCoordinates = !this.showDebugCoordinates
        this.resizeAndRedraw()
      }
    }

    this.viewCanvas.style.cursor = "grab"
    this.viewCanvas.addEventListener("wheel", this.onWheel, {passive: false})
    this.viewCanvas.addEventListener("pointerdown", this.onPointerDown)
    this.viewCanvas.addEventListener("pointerup", this.onPointerUp)
    this.viewCanvas.addEventListener("pointercancel", this.onPointerCancel)
    this.viewCanvas.addEventListener("dblclick", this.onDoubleClick)
    this.controls.addEventListener("click", this.onControlClick)
    window.addEventListener("pointermove", this.onPointerMove)
    window.addEventListener("pointerup", this.onPointerUp)
    window.addEventListener("blur", this.onWindowBlur)
    window.addEventListener("keydown", this.onKeyDown)
    document.addEventListener("visibilitychange", this.onVisibilityChange)

    this.resizeObserver = new ResizeObserver(() => this.resizeAndRedraw())
    this.resizeObserver.observe(this.container)
    this.onWindowResize = () => this.resizeAndRedraw()
    window.addEventListener("resize", this.onWindowResize)

    this.resizeAndRedraw()

    this.handleEvent("entities", ({entities}) => {
      const safeEntities = Array.isArray(entities) ? entities : []
      this.projection = projectEntities(safeEntities, this.rowsCols.rows, this.rowsCols.cols)
    })

    this.startRenderLoop()
  },

  destroyed() {
    if (this.animationFrameId !== null) {
      window.cancelAnimationFrame(this.animationFrameId)
      this.animationFrameId = null
    }

    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
      this.resizeObserver = null
    }

    if (this.viewCanvas) {
      this.viewCanvas.removeEventListener("wheel", this.onWheel)
      this.viewCanvas.removeEventListener("pointerdown", this.onPointerDown)
      this.viewCanvas.removeEventListener("pointerup", this.onPointerUp)
      this.viewCanvas.removeEventListener("pointercancel", this.onPointerCancel)
      this.viewCanvas.removeEventListener("dblclick", this.onDoubleClick)
      this.viewCanvas.style.cursor = "default"
    }

    if (this.controls) {
      this.controls.removeEventListener("click", this.onControlClick)
    }

    window.removeEventListener("pointermove", this.onPointerMove)
    window.removeEventListener("pointerup", this.onPointerUp)
    window.removeEventListener("blur", this.onWindowBlur)
    window.removeEventListener("resize", this.onWindowResize)
    window.removeEventListener("keydown", this.onKeyDown)
    document.removeEventListener("visibilitychange", this.onVisibilityChange)

    if (this.hud?.parentElement) {
      this.hud.parentElement.removeChild(this.hud)
    }

    if (this.controls?.parentElement) {
      this.controls.parentElement.removeChild(this.controls)
    }
  },

  startRenderLoop() {
    const render = () => {
      if (this.surface && this.transform && Number.isFinite(this.size)) {
        drawProjectedEntities(this.surface.entityCtx, this.transform, this.size, this.projection)
        compositeLayers(this.surface, this.size)
      }

      this.animationFrameId = window.requestAnimationFrame(render)
    }

    this.animationFrameId = window.requestAnimationFrame(render)
  },
}
