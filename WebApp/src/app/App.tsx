import { ReactNode } from 'react'
import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router'
import { MantineProvider, Loader } from '@mantine/core'

import { AuthProvider, useAuth, PathProvider, ApiProvider } from './contexts'
import theme from './mantine-theme'
import LoginPage from 'src/app/pages/LoginPage'
import DashboardLayout from './pages/DashboardLayout'
import ProfilePage from './pages/ProfilePage'
import quizAppRoutes from 'src/quiz-app/routes'
import adminAppRoutes from 'src/admin-app/routes'

function App() {
  return (
    <MantineProvider defaultColorScheme='dark' theme={theme}>
      <AuthProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </AuthProvider>
    </MantineProvider>
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
      {quizAppRoutes}
    </Route>
    <Route path='admin' element={
      <SubappLayout path='/admin' apiPath='/api/admin' />
    }>
      {adminAppRoutes}
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