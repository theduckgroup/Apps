import { createContext, useContext } from 'react'

export interface Info {
  env: string | 'production'
  lastUpdated?: string
}

export interface EnvContextValue {
  info: Info | undefined
}

export const EnvContext = createContext<EnvContextValue | undefined>(undefined)

export function useEnv() {
  return useContext(EnvContext)!
}
