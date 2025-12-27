import { Navigate, Route } from 'react-router'
import RootPage from './pages/RootPage'
import StoreEditorPage from './pages/StoreEditorPage'

export default (
  <>
    <Route index element={<RootPage />} />
    <Route path='store/editor' element={<StoreEditorPage />} />
  </>
)