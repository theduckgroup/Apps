import { Navigate, Route } from 'react-router'
import TemplateListPage from './pages/TemplateListPage'
import TemplateEditorPage from './pages/TemplateEditorPage'

export default (
  <>
    <Route index element={<Navigate to='templates' replace />} />
    <Route path='templates' element={<TemplateListPage />} />
    <Route path='template' element={<TemplateEditorPage />} />
    <Route path='template/:templateId' element={<TemplateEditorPage />} />
  </>
)
