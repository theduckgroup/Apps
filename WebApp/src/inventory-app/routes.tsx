import { Route } from 'react-router'
import RootPage from './pages/RootPage'
import StoreEditorPage from './pages/StoreEditorPage'
import { withErrorBoundary } from 'src/utils/with-error-boundary'

export default (
  <>
    <Route index element={withErrorBoundary(<RootPage />)} />
    <Route path='store/editor' element={withErrorBoundary(<StoreEditorPage />)} />
  </>
)