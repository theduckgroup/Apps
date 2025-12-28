import { Navigate, Route } from 'react-router'
import QuizListPage from './pages/QuizListPage'
import QuizEditorPage from './pages/QuizEditorPage'
import { withErrorBoundary } from 'src/utils/with-error-boundary'

export default (
  <>
    <Route index element={<Navigate to='list' replace />} />
    <Route path='list' element={withErrorBoundary(<QuizListPage />)} />
    <Route path='quiz' element={withErrorBoundary(<QuizEditorPage />)} />
    <Route path='quiz/:quizId' element={withErrorBoundary(<QuizEditorPage />)} />
  </>
)