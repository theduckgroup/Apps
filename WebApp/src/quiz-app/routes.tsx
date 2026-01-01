import { Navigate, RouteObject } from 'react-router'
import QuizListPage from './pages/QuizListPage'
import QuizEditorPage from './pages/QuizEditorPage'
import { withErrorBoundary } from 'src/utils/with-error-boundary'

const routes: RouteObject[] = [
  { index: true, element: <Navigate to='list' replace /> },
  { path: 'list', element: withErrorBoundary(<QuizListPage />) },
  { path: 'quiz', element: withErrorBoundary(<QuizEditorPage />) },
  { path: 'quiz/:quizId', element: withErrorBoundary(<QuizEditorPage />) }
]

export default routes