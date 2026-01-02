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

export function useElementRect(elementRef: React.RefObject<HTMLElement | null>): ElementRect | null {
  const [rect, setRect] = useState<ElementRect | null>(null)

  // This was used to clean up observation when elementRef changes
  // But we no longer do that...
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
  }, [elementRef])

  useEffect(() => {
    const element = elementRef.current

    if (!element) {
      setRect(null) // eslint-disable-line react-hooks/set-state-in-effect
      return
    }

    // Initial measurement
    updateRect()

    // Observe size changes
    const resizeObserver = new ResizeObserver(updateRect)
    resizeObserver.observe(element)
    resizeObserverRef.current = resizeObserver

    // Observe scroll and window resize
    window.addEventListener('scroll', updateRect)
    window.addEventListener('resize', updateRect)

    return () => {
      resizeObserver.disconnect()
      window.removeEventListener('scroll', updateRect)
      window.removeEventListener('resize', updateRect)
    }
  }, [updateRect, elementRef])

  return rect
}