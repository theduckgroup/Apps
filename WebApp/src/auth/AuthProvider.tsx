import { ReactNode, useEffect, useState } from 'react'

import { Session } from '@supabase/supabase-js'
import supabase from './supabase-client'

import { AuthContext, AuthContextValue } from './AuthContext'

// This is part of AuthContext, but split into separate file
// due to fast refresh restrictions 
// (can't export interface and component in the same file)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [isLoaded, setIsLoaded] = useState(false)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setIsLoaded(true)
    })
    
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [])

  const value: AuthContextValue = {
    isLoaded,
    user: session?.user,
    login: async (options) => {
      const response = await supabase.auth.signInWithPassword(options)

      if (response.error) {
        throw response.error
      }
      
      return
    },
    logout: () => supabase.auth.signOut()
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}
