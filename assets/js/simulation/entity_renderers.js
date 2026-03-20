import {gridToPixel, cellTopLeft} from "./canvas_transform"

const STYLES = {
  gridMinor: "#b0bccb",
  gridMajor: "#8f9db0",
  background: "#f8fafc",
  busBody: "#2563eb",
  busAccent: "#1e3a8a",
  busWindow: "#dbeafe",
  stopPole: "#3f3f46",
  stopSign: "#facc15",
  stopRing: "#65a30d",
  stopLetter: "#3f6212",
  stopInner: "#3f6212",
  citizen: "#f97316",
  citizenShadow: "rgba(194, 65, 12, 0.28)",
  crowdText: "#fff",
  crowdOutline: "#000",
  crowdFont: "bold 14px sans-serif",
}

function majorStep(count) {
  if (count >= 120) {
    return 20
  }

  if (count >= 60) {
    return 10
  }

  if (count >= 25) {
    return 5
  }

  return 4
}

function labelStep(transform, majorEvery) {
  if (transform.zoom >= 2.8) {
    return Math.max(1, Math.floor(majorEvery / 2))
  }

  if (transform.zoom >= 2.1) {
    return majorEvery
  }

  if (transform.zoom >= 1.9) {
    return majorEvery
  }

  if (transform.zoom >= 1.5) {
    return majorEvery * 2
  }

  return majorEvery * 4
}

function coordinateLabel(col, row) {
  return `(${col + 1},${row + 1})`
}

function drawCoordinateLabels(gridCtx, transform, step) {
  const {rows, cols, cellWidth, cellHeight, offsetX, offsetY} = transform

  if (step === 1 && (rows > 35 || cols > 35)) {
    return
  }

  const fontSize = Math.max(7, Math.min(11, Math.floor(Math.min(cellWidth, cellHeight) * 0.28)))
  gridCtx.font = `${fontSize}px ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`
  gridCtx.textAlign = "left"
  gridCtx.textBaseline = "top"
  gridCtx.fillStyle = "rgba(15, 23, 42, 0.55)"
  const padding = 4

  for (let row = 0; row < rows; row += step) {
    for (let col = 0; col < cols; col += step) {
      const label = coordinateLabel(col, row)
      const metrics = gridCtx.measureText(label)
      const maxWidth = metrics.width

      const cellLeft = offsetX + col * cellWidth
      const cellRight = cellLeft + cellWidth
      const cellTop = offsetY + row * cellHeight
      const cellBottom = cellTop + cellHeight

      let labelX = cellLeft + 3
      const labelY = cellTop + 2

      if (labelX + maxWidth + padding > cellRight) {
        labelX = Math.max(cellLeft + 1, cellRight - maxWidth - padding)
      }

      if (labelX + maxWidth > offsetX + cols * cellWidth - padding) {
        labelX = Math.max(offsetX + 1, offsetX + cols * cellWidth - maxWidth - padding)
      }

      if (labelY + fontSize > cellBottom) {
        continue
      }

      gridCtx.fillText(label, labelX, labelY)
    }
  }
}

export function drawGrid(gridCtx, transform, size) {
  const {rows, cols, cellWidth, cellHeight, offsetX, offsetY, zoom} = transform
  const gridWidth = cols * cellWidth
  const gridHeight = rows * cellHeight
  const majorEvery = majorStep(Math.max(rows, cols))
  const top = Math.round(offsetY)
  const left = Math.round(offsetX)
  const bottom = Math.round(offsetY + gridHeight)
  const right = Math.round(offsetX + gridWidth)
  const gridDrawHeight = Math.max(1, bottom - top)
  const gridDrawWidth = Math.max(1, right - left)

  gridCtx.clearRect(0, 0, size, size)
  gridCtx.fillStyle = STYLES.background
  gridCtx.fillRect(0, 0, size, size)

  for (let col = 0; col <= cols; col += 1) {
    const x = Math.round(offsetX + col * cellWidth)
    const baseZoom = zoom <= 1.05
    const thickness = baseZoom ? 1.1 : (col % majorEvery === 0 ? 1.5 : 1)

    gridCtx.fillStyle = baseZoom ? STYLES.gridMinor : (col % majorEvery === 0 ? STYLES.gridMajor : STYLES.gridMinor)
    gridCtx.fillRect(x - thickness / 2, top, thickness, gridDrawHeight)
  }

  for (let row = 0; row <= rows; row += 1) {
    const y = Math.round(offsetY + row * cellHeight)
    const baseZoom = zoom <= 1.05
    const thickness = baseZoom ? 1.1 : (row % majorEvery === 0 ? 1.5 : 1)

    gridCtx.fillStyle = baseZoom ? STYLES.gridMinor : (row % majorEvery === 0 ? STYLES.gridMajor : STYLES.gridMinor)
    gridCtx.fillRect(left, y - thickness / 2, gridDrawWidth, thickness)
  }

  if (transform.showDebugCoordinates || zoom >= 1.5) {
    const step = transform.showDebugCoordinates ? 1 : labelStep(transform, majorEvery)
    drawCoordinateLabels(gridCtx, transform, step)
  }
}

function drawStop(ctx, transform, entity) {
  const cellSize = Math.min(transform.cellWidth, transform.cellHeight)
  const sizeScale = Math.max(1, cellSize / 8)
  const signRadius = Math.max(2.8, Math.min(6.8, 2.8 * sizeScale))
  const innerRadius = Math.max(0.9, Math.min(2.7, signRadius * 0.46))
  const ringWidth = Math.max(0.9, Math.min(1.6, signRadius * 0.26))
  const showLetter = cellSize >= 8 && transform.zoom >= 1
  const {px, py} = gridToPixel(transform, entity.x, entity.y)
  const signCenterY = py

  ctx.fillStyle = STYLES.stopSign
  ctx.beginPath()
  ctx.arc(px, signCenterY, signRadius, 0, 2 * Math.PI)
  ctx.fill()

  ctx.strokeStyle = STYLES.stopRing
  ctx.lineWidth = ringWidth
  ctx.beginPath()
  ctx.arc(px, signCenterY, signRadius - ringWidth * 0.5, 0, 2 * Math.PI)
  ctx.stroke()

  if (showLetter) {
    const letterSize = Math.max(4.4, Math.min(10.5, signRadius * 1.42))
    ctx.fillStyle = STYLES.stopLetter
    ctx.font = `700 ${letterSize}px ui-sans-serif, system-ui, -apple-system, Segoe UI, sans-serif`
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    ctx.fillText("H", px, signCenterY + 0.2)
  } else {
    ctx.fillStyle = STYLES.stopInner
    ctx.beginPath()
    ctx.arc(px, signCenterY, innerRadius, 0, 2 * Math.PI)
    ctx.fill()
  }

}

function roundRect(ctx, x, y, width, height, radius) {
  const safeRadius = Math.max(0, Math.min(radius, width / 2, height / 2))

  ctx.beginPath()
  ctx.moveTo(x + safeRadius, y)
  ctx.arcTo(x + width, y, x + width, y + height, safeRadius)
  ctx.arcTo(x + width, y + height, x, y + height, safeRadius)
  ctx.arcTo(x, y + height, x, y, safeRadius)
  ctx.arcTo(x, y, x + width, y, safeRadius)
  ctx.closePath()
}

function drawBus(ctx, transform, entity) {
  const {px, py} = gridToPixel(transform, entity.x, entity.y)
  const bodyWidth = Math.max(6, transform.cellWidth * 0.72)
  const bodyHeight = Math.max(4, transform.cellHeight * 0.46)
  const radius = Math.min(4, Math.max(1.5, Math.min(bodyWidth, bodyHeight) * 0.2))
  const left = px - bodyWidth / 2
  const top = py - bodyHeight / 2

  ctx.fillStyle = STYLES.busBody
  roundRect(ctx, left, top, bodyWidth, bodyHeight, radius)
  ctx.fill()

  ctx.fillStyle = STYLES.busAccent
  ctx.fillRect(left, top + bodyHeight - Math.max(1, bodyHeight * 0.25), bodyWidth, Math.max(1, bodyHeight * 0.25))

  const windowPadding = Math.max(0.8, bodyWidth * 0.08)
  ctx.fillStyle = STYLES.busWindow
  ctx.fillRect(
    left + windowPadding,
    top + windowPadding,
    bodyWidth - windowPadding * 2,
    Math.max(1.2, bodyHeight * 0.36),
  )
}

function drawCellHeat(ctx, transform, crowd) {
  if (crowd.count < 3) {
    return
  }

  const {px, py} = cellTopLeft(transform, crowd.x, crowd.y)
  const intensity = Math.min(0.18, 0.06 + Math.log(crowd.count) * 0.025)

  ctx.fillStyle = `rgba(249, 115, 22, ${intensity})`
  ctx.fillRect(px + 1, py + 1, Math.max(1, transform.cellWidth - 2), Math.max(1, transform.cellHeight - 2))
}

function drawCrowd(ctx, transform, crowd) {
  const {px, py} = gridToPixel(transform, crowd.x, crowd.y)
  const sizeScale = Math.max(1, Math.min(transform.cellWidth, transform.cellHeight) / 8)
  const baseRadius = Math.max(2, 2 * sizeScale)

  drawCellHeat(ctx, transform, crowd)

  ctx.fillStyle = STYLES.citizenShadow
  ctx.beginPath()
  ctx.arc(px + 0.6, py + 0.8, baseRadius, 0, 2 * Math.PI)
  ctx.fill()

  ctx.fillStyle = STYLES.citizen
  ctx.beginPath()

  if (crowd.count === 1) {
    ctx.arc(px, py, baseRadius, 0, 2 * Math.PI)
  } else {
    const radius = Math.min(baseRadius + Math.log(crowd.count) * 0.7, baseRadius * 2.2)
    ctx.arc(px, py, radius, 0, 2 * Math.PI)
  }

  ctx.fill()

  if (crowd.count > 1) {
    const text = crowd.count.toString()
    ctx.font = STYLES.crowdFont
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"

    ctx.strokeStyle = STYLES.crowdOutline
    ctx.lineWidth = 1
    ctx.strokeText(text, px, py)

    ctx.fillStyle = STYLES.crowdText
    ctx.fillText(text, px, py)
  }
}

const ENTITY_RENDERERS = {
  stop: drawStop,
  bus: drawBus,
}

export function drawProjectedEntities(entityCtx, transform, size, projection) {
  entityCtx.clearRect(0, 0, size, size)

  for (const entity of projection.fixedEntities) {
    const drawEntity = ENTITY_RENDERERS[entity.type]

    if (drawEntity) {
      drawEntity(entityCtx, transform, entity)
    }
  }

  for (const crowd of projection.crowds) {
    drawCrowd(entityCtx, transform, crowd)
  }
}
