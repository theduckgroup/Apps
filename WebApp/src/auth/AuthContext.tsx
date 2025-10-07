import { createContext, useContext } from 'react'
import { User } from '@supabase/supabase-js'

export interface AuthContextValue {
  isLoaded: boolean
  user?: User
  login: (options: {email: string, password: string}) => Promise<void>
  logout: () => void
}

export const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function useAuth() {
  return useContext(AuthContext)!
}