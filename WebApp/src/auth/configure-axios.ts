import axios from 'axios'
import supabase from './supabase-client'

axios.interceptors.request.use(async config => {
  const session = (await supabase.auth.getSession()).data.session

  if (session) {
    config.headers['Authorization'] = `Bearer ${session.access_token}`
    
  }

  return config
})

// Use cookies
// axios.defaults.withCredentials = true

/*
// Translates errors.
axios.interceptors.response.use(
  response => response,
  (error: AxiosError) => {
    // AxiosError.toString() doesn't include response data
    // Errors sent by our backends always include message and stack in response data (due to express-error-response middleware)
    // e.g., { message: ..., stack: ...}

    // Uncomment to show entire error, including stack
    // console.error(error)

    const response = error.response
    const data = response?.data as any
    
    if (data && data.message) {
      // Uncomment to show stack
      // console.error(data.stack)

      throw new Error(data.message)

    } else {
      throw error
    }
  }
)
*/