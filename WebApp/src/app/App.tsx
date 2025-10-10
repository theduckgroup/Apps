import { ReactNode } from 'react'
import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router'
import { Loader } from '@mantine/core'

import { useAuth } from './providers/AuthContext'
import { AuthProvider } from './providers/AuthProvider'
import { PathProvider } from './providers/PathProvider'
import { ApiProvider } from './providers/ApiProvider'
import LoginPage from 'src/app/LoginPage'
import DashboardLayout from './DashboardLayout'
import ProfilePage from './ProfilePage'
import quizRoutes from 'src/quiz'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  )
}

function AppRoutes() {
  // Used to wait for session to be restored
  // Without this it will always redirect to login at startup
  // Then redirect to default authenticated page after session is restored
  const { isLoaded } = useAuth()

  return (
    isLoaded ?
      <Routes>
        <>
          <Route path='login' element={
            <RedirectToRootIfAuthenticated>
              <LoginPage />
            </RedirectToRootIfAuthenticated>
          } />

          <Route path='/' element={
            <RedirectToLoginIfUnauthenticated>
              <DashboardLayout />
            </RedirectToLoginIfUnauthenticated>
          }>
            <Route index element={<Navigate to='quiz-app' />} />
            {subappRoutes}
            <Route path='profile' element={<ProfilePage />} />
            <Route path='*' element={<NoMatch />} />
          </Route>
        </>
      </Routes >
      :
      <LoadingPage />
  )
}

// Apps

const subappRoutes = (
  <>
    <Route path='quiz-app' element={
      <SubappLayout path='/quiz-app' apiPath='/api/quiz-app' />
    }>
      {quizRoutes}
    </Route>
  </>
)

function SubappLayout({ path, apiPath }: {
  path: string,
  apiPath: string
}) {
  return (
    <PathProvider path={path}>
      <ApiProvider baseUrl={apiPath}>
        <Outlet />
      </ApiProvider>
    </PathProvider>
  )
}

// Loading & Redirects

function LoadingPage() {
  return (
    <div className='w-screen h-screen flex justify-center content-center'>
      <Loader className='m-auto' />
    </div>
  )
}

function RedirectToLoginIfUnauthenticated({ children }: { children: ReactNode }) {
  const { user } = useAuth()

  if (!user) {
    return <Navigate to='/login' replace />
  }

  return children
}

function RedirectToRootIfAuthenticated({ children }: { children: ReactNode }) {
  const { user } = useAuth()

  if (user) {
    return <Navigate to='/' replace />
  }

  return children
}

function NoMatch() {
  return (
    <h3>
      <p>Page not found... What was you trying to do?</p>
    </h3>
  )
}

export default App