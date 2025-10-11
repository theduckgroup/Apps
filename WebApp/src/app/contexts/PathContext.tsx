import { createContext, useContext } from 'react'
import { NavigateOptions } from 'react-router'

export interface PathContextValue {
  navigate: (to: string, options?: NavigateOptions) => void | Promise<void>
}

export const PathContext = createContext<PathContextValue | undefined>(undefined)

export function usePath() {
  return useContext(PathContext)!
}