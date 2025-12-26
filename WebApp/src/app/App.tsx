import { ReactNode, useEffect } from 'react'
import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router'
import { MantineProvider, Loader, Text } from '@mantine/core'

// import env from 'src/env'
import { AuthProvider, useAuth, PathProvider, ApiProvider } from './contexts'
import theme from './mantine-theme'
import LoginPage from 'src/app/pages/LoginPage'
import DashboardLayout from './pages/DashboardLayout'
import ProfilePage from './pages/ProfilePage'
import ResetPasswordPage from './pages/ResetPasswordPage'
import ResetPassword2Page from './pages/ResetPassword2Page'
import adminAppRoutes from 'src/admin-app/routes'
import quizAppRoutes from 'src/quiz-app/routes'
import QuizResponsePage from 'src/quiz-app/pages/QuizResponsePage'
import weeklySpendingApp from 'src/ws-app/routes'


function App() {
  useEffect(() => {
    // On deployment, hosting service replaces the static files while the client app still points to the old files
    // Force a reload, albeit with a delay just in case it runs into a loop or sth
    window.addEventListener('vite:preloadError', (event) => {
      setTimeout(() => {
        window.location.reload()
      }, 3000)
    })
  }, [])

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

  if (!isLoaded) {
    return <LoadingPage />
  }

  return (
    <Routes>
      <Route path='login' element={
        <RedirectToRootIfAuthorized>
          <LoginPage />
        </RedirectToRootIfAuthorized>
      } />

      <Route path='reset-password' element={
        <RedirectToRootIfAuthorized>
          <ResetPasswordPage />
        </RedirectToRootIfAuthorized>
      } />

      <Route path='reset-password-2' element={
        <RedirectToLoginIfUnauthorized>
          <ResetPassword2Page />
        </RedirectToLoginIfUnauthorized>
      } />

      {fohTestViewQuizResponseRoute}

      <Route path='/' element={
        <RedirectToLoginIfUnauthorized>
          <DashboardLayout />
        </RedirectToLoginIfUnauthorized>
      }>
        <Route index element={<Navigate to='quiz-app' />} />
        {subappRoutes}
        <Route path='profile' element={<ProfilePage />} />
        <Route path='*' element={<NoMatch />} />
      </Route>
    </Routes>
  )
}

// (Sub)App routes

const subappRoutes = (
  <>
    <Route path='admin' element={
      <SubappLayout path='/admin' apiPath='/api/admin' />
    }>
      {adminAppRoutes}
    </Route>
    <Route path='quiz-app' element={
      <SubappLayout path='/quiz-app' apiPath='/api/quiz-app' />
    }>
      {quizAppRoutes}
    </Route>
    {
      <Route path='ws-app' element={
        <SubappLayout path='/ws-app' apiPath='/api/ws-app' />
      }>
        {weeklySpendingApp}
      </Route>
    }
  </>
)

const fohTestViewQuizResponseRoute = (
  <Route path='/fohtest/view/:id' element={
    <ApiProvider baseUrl='/api/quiz-app'>
      <QuizResponsePage />
    </ApiProvider>
  } />
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

function RedirectToLoginIfUnauthorized({ children }: { children: ReactNode }) {
  const { user, logout } = useAuth()

  if (!user) {
    return <Navigate to='/login' replace />
  }

  if (!user.isOwner && !user.isAdmin) {
    setTimeout(() => logout(), 3000)

    return (
      <>
        <Text c='red' p='lg'>Not Permitted</Text>
      </>
    )
  }

  return children
}

function RedirectToRootIfAuthorized({ children }: { children: ReactNode }) {
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