import eventHub from 'src/app/event-hub'

const quizEventHub = {
  onQuizzesChanged: (callback: () => void): () => void => {
    return eventHub.onEvent('quiz-app:quizzes:changed', callback)
  }
}

export default quizEventHub