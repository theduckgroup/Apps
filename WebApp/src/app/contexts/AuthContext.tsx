import { createContext, useContext } from 'react'
import { Session } from '@supabase/supabase-js'
import { User } from '../models/User'

export interface AuthContextValue {
  isLoaded: boolean
  user: User | null
  login: (options: {email: string, password: string}) => Promise<void>
  logout: () => Promise<void>,
  resetPassword: (email: string) => Promise<void>,
  getSession: () => Promise<Session | null>,
  removeSession: () => void
}

export const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function useAuth() {
  return useContext(AuthContext)!
}