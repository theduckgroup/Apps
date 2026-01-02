import { Navigate, RouteObject } from 'react-router'
import TemplateListPage from './pages/TemplateListPage'
import TemplateEditorPage from './pages/TemplateEditorPage'
import { withErrorBoundary } from 'src/utils/with-error-boundary'

const routes: RouteObject[] = [
  { index: true, element: <Navigate to='list' replace /> },
  { path: 'list', element: withErrorBoundary(<TemplateListPage />) },
  { path: 'template', element: withErrorBoundary(<TemplateEditorPage />) },
  { path: 'template/:templateId', element: withErrorBoundary(<TemplateEditorPage />) }
]

export default routes
