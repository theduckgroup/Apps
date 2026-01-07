import { RouteObject } from 'react-router'
import RootPage from './pages/RootPage'
import StoreEditorPage from './pages/StoreEditorPage'
import StockEditorPage from './pages/StockEditorPage'
import { withErrorBoundary } from 'src/utils/with-error-boundary'

const routes: RouteObject[] = [
  { index: true, element: withErrorBoundary(<RootPage />) },
  { path: 'store/:storeId/editor', element: withErrorBoundary(<StoreEditorPage />) },
  { path: 'store/:storeId/stock/editor', element: withErrorBoundary(<StockEditorPage />) }
]

export default routes