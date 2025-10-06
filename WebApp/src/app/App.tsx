import { ReactNode } from 'react'
import { Navigate, Route, Routes } from 'react-router'
import { Loader } from '@mantine/core'

import { useAuth } from '../auth/AuthContext'
import DashboardLayout from './DashboardLayout'
import LoginPage from 'src/auth/LoginPage'
import ProfilePage from './ProfilePage'
import QuizListPage from './QuizListPage'
import QuizPage from './QuizPage'

const App = () => {
  const { isLoaded } = { isLoaded: true }

  return (
    <>
      {isLoaded ?
        <Routes>
          <>
            <Route path='/login' element={
              <RedirectToRootIfAuthenticated>
                <LoginPage />
              </RedirectToRootIfAuthenticated>
            } />

            <Route path='/' element={
              <RedirectToLoginIfUnauthenticated>
                <DashboardLayout />
              </RedirectToLoginIfUnauthenticated>
            }>
              <Route index element={<Navigate to='/quiz-list' replace />} />
              <Route path='quiz-list' element={<QuizListPage />} />
              <Route path='quiz' element={<QuizPage />} />
              <Route path='quiz/:quizId' element={<QuizPage />} />
              <Route path='profile' element={<ProfilePage />} />
              <Route path='*' element={<NoMatch />} />
            </Route>
          </>
        </Routes>
        :
        <LoadingPage />
      }
    </>
  )
}

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

// function RedirectToFirstVendor() {
//   const { user } = useAuth()

//   return <Navigate to='/' replace />
// }

// function NavigateToLinkedVendor() {
//   const { user } = useAuth()

//   if (!user) {
//     return <Navigate to='/login' replace />
//   }

//   return <Navigate to='/' replace />
// }

function NoMatch() {
  // const location = useLocation()

  return (
    <h3>
      <p>Lalala</p>
      <p>Page not found... what was you trying to do?</p>
    </h3>
  )
}


export default App