import { ReactNode } from 'react'
import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router'
import { MantineProvider, Loader, Text } from '@mantine/core'

import { AuthProvider, useAuth, PathProvider, ApiProvider, EnvProvider } from './contexts'
import theme from './mantine-theme'
import LoginPage from 'src/app/pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import ProfilePage from './pages/ProfilePage'
import ResetPasswordPage from './pages/ResetPasswordPage'
import ResetPassword2Page from './pages/ResetPassword2Page'
import adminAppRoutes from 'src/admin-app/routes'
import quizAppRoutes from 'src/quiz-app/routes'
import QuizResponsePage from 'src/quiz-app/pages/QuizResponsePage'
import weeklySpendingApp from 'src/ws-app/routes'
import inventoryApp from 'src/inventory-app/routes'
import { withErrorBoundary } from 'src/utils/with-error-boundary'

function App() {
  return (
    <MantineProvider defaultColorScheme='dark' theme={theme}>
      <AuthProvider>
        <EnvProvider>
          <BrowserRouter>
            <AppRoutes />
          </BrowserRouter>
        </EnvProvider>
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
      {/* Login & reset password */}
      {loginRoutes}

      {/* Public routes */}
      {publicRoutes}

      {/* Authenticated routes */}
      <Route path='/' element={
        <RedirectToLoginIfUnauthorized>
          <DashboardPage />
        </RedirectToLoginIfUnauthorized>
      }>
        <Route index element={<Navigate to='quiz-app' />} />
        {subappRoutes}
        <Route path='profile' element={withErrorBoundary(<ProfilePage />)} />
        <Route path='*' element={<NoMatch />} />
      </Route>
    </Routes>
  )
}

// Login routes

const loginRoutes = (
  <>
    <Route path='/login' element={
      <RedirectToRootIfAuthorized>
        <LoginPage />
      </RedirectToRootIfAuthorized>
    } />

    <Route path='/reset-password' element={
      <RedirectToRootIfAuthorized>
        <ResetPasswordPage />
      </RedirectToRootIfAuthorized>
    } />

    <Route path='/reset-password-2' element={
      <RedirectToLoginIfUnauthorized>
        <ResetPassword2Page />
      </RedirectToLoginIfUnauthorized>
    } />
  </>
)

// Public routes

const publicRoutes = (
  <>
    <Route path='/fohtest/view/:id' element={
      <ApiProvider baseUrl='/api/quiz-app'>
        <QuizResponsePage />
      </ApiProvider>
    } />
  </>
)

// (Sub)App routes

const subappRoutes = (
  <>
    {/* Admin */}
    <Route path='admin' element={
      <SubappLayout path='/admin' apiPath='/api/admin' />
    }>
      {adminAppRoutes}
    </Route>
    {/* Quiz */}
    <Route path='quiz-app' element={
      <SubappLayout path='/quiz-app' apiPath='/api/quiz-app' />
    }>
      {quizAppRoutes}
    </Route>
    {/* Weekly Spending */}
    <Route path='ws-app' element={
      <SubappLayout path='/ws-app' apiPath='/api/ws-app' />
    }>
      {weeklySpendingApp}
    </Route>
    {/* Inventory */}
    <Route path='inventory-app' element={
      <SubappLayout path='/inventory-app' apiPath='/api/inventory-app' />
    }>
      {inventoryApp}
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