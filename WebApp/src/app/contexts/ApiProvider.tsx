import axios from 'axios'
import { useAuth } from './AuthContext'
import { ApiContext, ApiContextValue } from './ApiContext'

export { ApiContext }

export function ApiProvider({ baseUrl, children }: {
  baseUrl: string,
  children: React.ReactNode
}) {
  const { getSession, logout } = useAuth()

  const axiosInstance = axios.create({
    baseURL: baseUrl // Just /api/quiz-app or sth, not full url
  })

  axiosInstance.interceptors.request.use(async request => {
    const session = await getSession()

    if (session) {
      request.headers['Authorization'] = `Bearer ${session.access_token}`
    }

    return request
  })

  axiosInstance.interceptors.response.use(
    async response => {
      if (response.status == 401) {
        await logout()
      }

      return response
    },
    async error => {
      if (axios.isAxiosError(error)) {
        if (error.response?.status == 401) {
          await logout()
        }
      }

      throw error
    }
  )

  const value: ApiContextValue = {
    axios: axiosInstance
  }

  return (
    <ApiContext value={value}>
      {children}
    </ApiContext>
  )
}