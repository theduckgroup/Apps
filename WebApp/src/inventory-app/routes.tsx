import { RouteObject } from 'react-router'
import RootPage from './pages/RootPage'
import StoreEditorPage from './pages/StoreEditorPage'
import { withErrorBoundary } from 'src/utils/with-error-boundary'

const routes: RouteObject[] = [
  { index: true, element: withErrorBoundary(<RootPage />) },
  { path: 'store/:storeId/editor', element: withErrorBoundary(<StoreEditorPage />) }
]

export default routes