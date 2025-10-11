import { Navigate, Route } from 'react-router'
import QuizListPage from './pages/QuizListPage'
import QuizPage from './pages/QuizPage'

export default (
  <>
    <Route index element={<Navigate to='list' replace />} />
    <Route path='list' element={<QuizListPage />} />
    <Route path='quiz' element={<QuizPage />} />
    <Route path='quiz/:quizId' element={<QuizPage />} />
  </>
)