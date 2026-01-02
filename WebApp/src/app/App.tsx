import { ReactNode } from 'react'
import { createBrowserRouter, Navigate, Outlet, RouteObject, RouterProvider } from 'react-router'
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
          <RouterProvider router={createRouter()} />
        </EnvProvider>
      </AuthProvider>
    </MantineProvider>
  )
}

function AuthLoader() {
  // Used to wait for session to be restored
  // Without this it will always redirect to login at startup
  // Then redirect to default authenticated page after session is restored
  const { isLoaded } = useAuth()

  if (!isLoaded) {
    return <LoadingPage />
  }

  return <Outlet />
}

// Router

function createRouter() {
  return createBrowserRouter([
    {
      element: <AuthLoader />,
      children: [
        ...createLoginRoutes(),
        ...createPublicRoutes(),
        {
          // Authenticated routes
          path: '/',
          element: (
            <RedirectToLoginIfUnauthorized>
              <DashboardPage />
            </RedirectToLoginIfUnauthorized>
          ),
          children: [
            { index: true, element: <Navigate to='quiz-app' /> },
            ...createSubappRoutes(),
            { path: 'profile', element: withErrorBoundary(<ProfilePage />) },
            { path: '*', element: <NoMatch /> }
          ]
        }
      ]
    }
  ])
}

// Login routes

function createLoginRoutes(): RouteObject[] {
  return [
    {
      path: '/login',
      element: (
        <RedirectToRootIfAuthorized>
          <LoginPage />
        </RedirectToRootIfAuthorized>
      )
    },
    {
      path: '/reset-password',
      element: (
        <RedirectToRootIfAuthorized>
          <ResetPasswordPage />
        </RedirectToRootIfAuthorized>
      )
    },
    {
      path: '/reset-password-2',
      element: (
        <RedirectToLoginIfUnauthorized>
          <ResetPassword2Page />
        </RedirectToLoginIfUnauthorized>
      )
    }
  ]
}

// Public routes

function createPublicRoutes(): RouteObject[] {
  return [
    {
      path: '/fohtest/view/:id',
      element: (
        <ApiProvider baseUrl='/api/quiz-app'>
          <QuizResponsePage />
        </ApiProvider>
      )
    }
  ]
}

// (Sub)App routes

function createSubappRoutes(): RouteObject[] {
  return [
    {
      path: 'admin',
      element: <SubappLayout path='/admin' apiPath='/api/admin' />,
      children: adminAppRoutes
    },
    {
      path: 'quiz-app',
      element: <SubappLayout path='/quiz-app' apiPath='/api/quiz-app' />,
      children: quizAppRoutes
    },
    {
      path: 'ws-app',
      element: <SubappLayout path='/ws-app' apiPath='/api/ws-app' />,
      children: weeklySpendingApp
    },
    {
      path: 'inventory-app',
      element: <SubappLayout path='/inventory-app' apiPath='/api/inventory-app' />,
      children: inventoryApp
    }
  ]
}

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
      <p>Page not found...</p>
    </h3>
  )
}

export default App