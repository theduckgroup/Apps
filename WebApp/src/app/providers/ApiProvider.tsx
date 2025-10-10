import axios from 'axios';
import { ApiContext, ApiContextValue } from 'src/app/providers/ApiContext';
import { useAuth } from 'src/app/providers/AuthContext';

export function ApiProvider({ baseUrl, children }: {
  baseUrl: string,
  children: React.ReactNode
}) {
  const { getSession, logout } = useAuth()

  const axiosInstance = axios.create({
    baseURL: baseUrl // Just /api/quiz-app or sth, not full url
  })

  axiosInstance.interceptors.request.use(async config => {
    const session = await getSession()

    if (session) {
      config.headers['Authorization'] = `Bearer ${session.access_token}`
    }

    return config
  })

  axiosInstance.interceptors.response.use(async config => {
    if (config.status == 401) {
      await logout()
    }

    return config
  })

  const value: ApiContextValue = {
    axios: axiosInstance
  }

  return (
    <ApiContext.Provider value={value}>
      {children}
    </ApiContext.Provider>
  )
}