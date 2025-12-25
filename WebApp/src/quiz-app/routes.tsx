import { Navigate, Route } from 'react-router'
import QuizListPage from './pages/QuizListPage'
import QuizEditorPage from './pages/QuizEditorPage'

export default (
  <>
    <Route index element={<Navigate to='list' replace />} />
    <Route path='list' element={<QuizListPage />} />
    <Route path='quiz' element={<QuizEditorPage />} />
    <Route path='quiz/:quizId' element={<QuizEditorPage />} />
  </>
)