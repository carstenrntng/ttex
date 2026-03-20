import {clampToGrid} from "./canvas_transform"

function crowdKey(x, y) {
  return `${x},${y}`
}

export function projectEntities(entities, rows, cols) {
  const fixedEntities = []
  const crowds = new Map()

  for (const entity of entities) {
    if (!Number.isFinite(entity?.x) || !Number.isFinite(entity?.y) || typeof entity?.type !== "string") {
      continue
    }

    const clamped = clampToGrid(entity, rows, cols)

    if (clamped.type === "citizen") {
      const key = crowdKey(clamped.x, clamped.y)

      if (!crowds.has(key)) {
        crowds.set(key, {x: clamped.x, y: clamped.y, count: 0})
      }

      crowds.get(key).count += 1
      continue
    }

    fixedEntities.push(clamped)
  }

  return {
    fixedEntities,
    crowds: Array.from(crowds.values()),
  }
}
