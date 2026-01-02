import { Navigate, RouteObject } from 'react-router'
import UsersPage from './pages/UsersPage'
import ProfilePage from 'src/app/pages/ProfilePage'

const routes: RouteObject[] = [
  { index: true, element: <Navigate to='users' replace /> },
  { path: 'users', element: <UsersPage /> },
  // { path: 'users/:userId/sessions', element: <UserSessionsPage /> },
  { path: 'profile', element: <ProfilePage /> }
]

export default routes
