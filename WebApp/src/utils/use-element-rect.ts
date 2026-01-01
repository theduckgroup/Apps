import { useEffect, useRef, useState } from 'react'

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

export interface UseElementRectOptions {
  /**
   * Whether to observe element size changes
   * @default true
   */
  observeSize?: boolean

  /**
   * Whether to observe scroll/resize events
   * @default true
   */
  observeScroll?: boolean
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
  options: UseElementRectOptions = {}
): [React.RefObject<T | null>, ElementRect | null] {
  const { observeSize = true, observeScroll = true } = options
  const ref = useRef<T | null>(null)
  const [rect, setRect] = useState<ElementRect | null>(null)

  useEffect(() => {
    const element = ref.current
    if (!element) return

    const updateRect = () => {
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
    }

    // Initial measurement
    updateRect()

    // Observe size changes
    let resizeObserver: ResizeObserver | null = null
    if (observeSize) {
      resizeObserver = new ResizeObserver(updateRect)
      resizeObserver.observe(element)
    }

    // Observe scroll and window resize
    if (observeScroll) {
      window.addEventListener('scroll', updateRect, true) // Use capture to catch all scrolls
      window.addEventListener('resize', updateRect)
    }

    return () => {
      if (resizeObserver) {
        resizeObserver.disconnect()
      }
      if (observeScroll) {
        window.removeEventListener('scroll', updateRect, true)
        window.removeEventListener('resize', updateRect)
      }
    }
  }, [observeSize, observeScroll])

  return [ref, rect]
}
