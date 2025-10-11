import eventHub from 'src/app/event-hub'

export default {
  onQuizzesChanged(callback: () => void): () => void {
    return eventHub.onEvent('quiz-app:quizzes:changed', callback)
  }
}