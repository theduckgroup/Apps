import { ReactNode, useEffect, useState } from 'react'
import { Session, createClient } from '@supabase/supabase-js'

import { AuthContext, AuthContextValue } from './AuthContext'

// This is part of AuthContext, but split into separate file
// due to fast refresh restrictions 
// (can't export interface and component in the same file)

const supabase = createClient('https://ahvebevkycanekqtnthy.supabase.co', 'sb_publishable_RYskGh0Y71aGJoncWRLZDQ_rp9Z0U2u')

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

  function removeSession() {
    [window.localStorage, window.sessionStorage].forEach((storage) => {
      Object.entries(storage).forEach(([key]) => {
        storage.removeItem(key)
      })
    })
  }

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
    logout: async () => {
      try {
        const response = await supabase.auth.signOut()

        if (response.error) {
          throw response.error
        }

      } catch (e) {
        console.error(e)

      } finally {
        removeSession()
      }
    },
    getSession: async () => {
      return (await supabase.auth.getSession()).data.session
    },
    removeSession,
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}