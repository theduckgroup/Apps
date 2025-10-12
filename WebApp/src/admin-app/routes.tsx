import { Navigate, Route } from 'react-router'
import UsersPage from './pages/UsersPage'
import ProfilePage from 'src/app/pages/ProfilePage'

export default (
  <>
    <Route index element={<Navigate to='users' replace />} />
    <Route path='users' element={<UsersPage />} />
    {/* <Route path='users/:userId/sessions' element={<UserSessionsPage />} /> */}
    <Route path='profile' element={<ProfilePage />} />
  </>
)
