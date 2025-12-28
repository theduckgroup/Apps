import { Navigate, Route } from 'react-router'
import TemplateListPage from './pages/TemplateListPage'
import TemplateEditorPage from './pages/TemplateEditorPage'
import { withErrorBoundary } from 'src/utils/with-error-boundary'

export default (
  <>
    <Route index element={<Navigate to='list' replace />} />
    <Route path='list' element={withErrorBoundary(<TemplateListPage />)} />
    <Route path='template' element={withErrorBoundary(<TemplateEditorPage />)} />
    <Route path='template/:templateId' element={withErrorBoundary(<TemplateEditorPage />)} />
  </>
)
