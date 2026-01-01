import { useCallback, useEffect, useRef, useState } from 'react'

export interface ElementRect {
  x: number
  y: number
  width: number
  height: number
  top: number
  right: number
  bottom: number
  left: number
}

/**
 * Hook that tracks an element's position and dimensions
 *
 * @example
 * ```tsx
 * function MyComponent() {
 *   const [ref, rect] = useElementRect()
 *
 *   return (
 *     <div ref={ref}>
 *       Position: {rect?.x}, {rect?.y}
 *     </div>
 *   )
 * }
 * ```
 */
export function useElementRect<T extends HTMLElement = HTMLElement>(

): [(node: T | null) => void, ElementRect | null] {
  const elementRef = useRef<T | null>(null)
  const [rect, setRect] = useState<ElementRect | null>(null)
  const resizeObserverRef = useRef<ResizeObserver | null>(null)

  const updateRect = useCallback(() => {
    const element = elementRef.current

    if (!element) {
      return
    }

    const domRect = element.getBoundingClientRect()

    setRect({
      x: domRect.x,
      y: domRect.y,
      width: domRect.width,
      height: domRect.height,
      top: domRect.top,
      right: domRect.right,
      bottom: domRect.bottom,
      left: domRect.left
    })
  }, [])

  const ref = useCallback((node: T | null) => {
    // Cleanup previous element
    if (resizeObserverRef.current) {
      resizeObserverRef.current.disconnect()
      resizeObserverRef.current = null
    }

    elementRef.current = node

    if (!node) {
      setRect(null)
      return
    }

    // Update rect immediately
    updateRect()
  }, [updateRect])

  useEffect(() => {
    const element = elementRef.current

    if (!element) {
      return
    }

    // Initial measurement
    updateRect()

    // Observe size changes
    const resizeObserver = new ResizeObserver(updateRect)
    resizeObserver.observe(element)
    resizeObserverRef.current = resizeObserver

    // Observe scroll and window resize
    window.addEventListener('scroll', updateRect, true) // Use capture to catch all scrolls
    window.addEventListener('resize', updateRect)

    return () => {
      resizeObserver.disconnect()
      window.removeEventListener('scroll', updateRect, true)
      window.removeEventListener('resize', updateRect)
    }
  }, [updateRect])

  return [ref, rect]
}
