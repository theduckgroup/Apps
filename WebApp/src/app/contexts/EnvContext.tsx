import { createContext, useContext } from 'react'

export interface Info {
  env: 'development' | 'production'
  lastUpdated?: string
}

export interface EnvContextValue {
  info: Info | undefined
}

export const EnvContext = createContext<EnvContextValue | undefined>(undefined)

export function useEnv() {
  return useContext(EnvContext)!
}
