import { Db } from 'mongodb'
import { DbQuiz } from './DbQuiz'
import { DbQuizResponse } from './DbQuizResponse'

declare module 'mongodb' {
  interface Db {
    collection_qz_quizzes: Collection<DbQuiz>
    collection_qz_quizResponses: Collection<DbQuizResponse>
  }
}

Object.defineProperty(Db.prototype, 'collection_qz_quizzes', {
  get(this: Db) {
    return this.collection<DbQuiz>('qz_quizzes')
  },
  enumerable: true, // Make it visible when iterating properties
  configurable: true, // Allow redefining if needed
})

Object.defineProperty(Db.prototype, 'collection_qz_quizResponses', {
  get(this: Db) {
    return this.collection<DbQuizResponse>('qz_quiz_responses')
  },
  enumerable: true,
  configurable: true,
})