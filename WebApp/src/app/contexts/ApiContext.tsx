import { createContext, useContext } from 'react'
import { Axios } from 'axios'

export interface ApiContextValue {
  axios: Axios
  // Future: unauthenticatedAxios
}

export const ApiContext = createContext<ApiContextValue | undefined>(undefined);

export function useApi() {
  return useContext(ApiContext)!
}