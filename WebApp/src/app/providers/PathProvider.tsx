import { useNavigate } from 'react-router'
import { PathContext, PathContextValue } from './PathContext'

export function PathProvider({ path, children }: {
  path: string,
  children: React.ReactNode
}) {
  const navigate = useNavigate()

  const value: PathContextValue = {
    navigate: (to, options) => {
      console.info(`! path = ${path}, to = ${to}`)
      console.info(`joined = ${joinPath(path, to)}`)
      return navigate(joinPath(path, to), options)
    }
  }

  return (
    <PathContext.Provider value={value}>
      {children}
    </PathContext.Provider>
  )
}

function joinPath(x: string, y: string): string {
  const x1 = x.replace(/^\/$/, '') // Trim trailing lash
  const y1 = y.replace(/^\//, '') // Trim leading slash
  return `${x1}/${y1}`
}