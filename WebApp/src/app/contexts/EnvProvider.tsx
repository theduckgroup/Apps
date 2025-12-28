import axios, { AxiosError } from 'axios'
import { useQuery } from '@tanstack/react-query'
import { EnvContext, EnvContextValue, Info } from './EnvContext'

export { EnvContext }

export function EnvProvider({ children }: {
  children: React.ReactNode
}) {
  const { data: info } = useQuery<Info, AxiosError>({
    queryKey: ['info'],
    queryFn: async () => (await axios.get<Info>('/api/info')).data
  })

  const value: EnvContextValue = {
    info
  }

  return (
    <EnvContext value={value}>
      {children}
    </EnvContext>
  )
}
