const FALLBACK_GRID_DIMENSION = 100
const CANVAS_VIEWPORT_HEIGHT_RATIO = 0.78

export function readGridDimensions(container) {
  const rows = Number.parseInt(container.dataset.gridRows, 10)
  const cols = Number.parseInt(container.dataset.gridCols, 10)

  return {
    rows: Number.isFinite(rows) && rows > 0 ? rows : FALLBACK_GRID_DIMENSION,
    cols: Number.isFinite(cols) && cols > 0 ? cols : FALLBACK_GRID_DIMENSION,
  }
}

export function computeCanvasMetrics(container, rows, cols) {
  const availableWidth = Math.max(1, container.clientWidth)
  const availableHeight = Math.max(1, Math.floor(window.innerHeight * CANVAS_VIEWPORT_HEIGHT_RATIO))
  const size = Math.floor(Math.min(availableWidth, availableHeight))

  const cellWidth = size / cols
  const cellHeight = size / rows

  return {
    size,
    cellWidth,
    cellHeight,
  }
}

export function gridToPixel(transform, x, y) {
  return {
    px: transform.offsetX + x * transform.cellWidth + transform.cellWidth / 2,
    py: transform.offsetY + y * transform.cellHeight + transform.cellHeight / 2,
  }
}

export function cellTopLeft(transform, x, y) {
  return {
    px: transform.offsetX + x * transform.cellWidth,
    py: transform.offsetY + y * transform.cellHeight,
  }
}

export function clampToGrid(entity, rows, cols) {
  const maxX = cols - 1
  const maxY = rows - 1

  const x = Math.max(0, Math.min(maxX, entity.x))
  const y = Math.max(0, Math.min(maxY, entity.y))

  return {
    ...entity,
    x,
    y,
  }
}
