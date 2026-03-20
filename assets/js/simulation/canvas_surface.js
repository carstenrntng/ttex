export function createCanvasSurface(viewCanvas) {
  const gridCanvas = document.createElement("canvas")
  const entityCanvas = document.createElement("canvas")

  const viewCtx = viewCanvas.getContext("2d", { alpha: false })
  const gridCtx = gridCanvas.getContext("2d", { alpha: false })
  const entityCtx = entityCanvas.getContext("2d")

  return {
    viewCanvas,
    gridCanvas,
    entityCanvas,
    viewCtx,
    gridCtx,
    entityCtx,
  }
}

export function resizeSurface(surface, size) {
  const dpr = window.devicePixelRatio || 1

  for (const canvas of [surface.viewCanvas, surface.gridCanvas, surface.entityCanvas]) {
    canvas.width = Math.round(size * dpr)
    canvas.height = Math.round(size * dpr)
  }

  surface.viewCanvas.style.width = `${size}px`
  surface.viewCanvas.style.height = `${size}px`

  for (const ctx of [surface.viewCtx, surface.gridCtx, surface.entityCtx]) {
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  }
}

export function compositeLayers(surface, size) {
  surface.viewCtx.clearRect(0, 0, size, size)
  surface.viewCtx.drawImage(
    surface.gridCanvas,
    0,
    0,
    surface.gridCanvas.width,
    surface.gridCanvas.height,
    0,
    0,
    size,
    size,
  )
  surface.viewCtx.drawImage(
    surface.entityCanvas,
    0,
    0,
    surface.entityCanvas.width,
    surface.entityCanvas.height,
    0,
    0,
    size,
    size,
  )
}
