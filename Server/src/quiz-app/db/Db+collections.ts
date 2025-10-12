import { Db } from 'mongodb'
import { DbQuiz } from './DbQuiz'
import { DbQuizResponse } from './DbQuizResponse'

declare module 'mongodb' {
  interface Db {
    collection_quizzes: Collection<DbQuiz>
    collection_quizResponses: Collection<DbQuizResponse>
  }
}

Object.defineProperty(Db.prototype, 'collection_quizzes', {
  get(this: Db) {
    return this.collection<DbQuiz>('quizzes')
  },
  enumerable: true, // Make it visible when iterating properties
  configurable: true, // Allow redefining if needed
})

Object.defineProperty(Db.prototype, 'collection_quizResponses', {
  get(this: Db) {
    return this.collection<DbQuizResponse>('quiz_responses')
  },
  enumerable: true,
  configurable: true,
})