import { Db } from 'mongodb'
import { DbUserData } from 'src/db/DbUserData';
import { DbQuiz } from 'src/db/DbQuiz';

declare module 'mongodb' {
  interface Db {
    collection_userData: Collection<DbUserData>
    collection_quizzes: Collection<DbQuiz>
  }
}

Object.defineProperty(Db.prototype, 'collection_quizzes', {
  get(this: Db) {
    return this.collection<DbQuiz>('quizzes')
  },
  enumerable: true, // Make it visible when iterating properties
  configurable: true, // Allow redefining if needed
})

Object.defineProperty(Db.prototype, 'collection_userData', {
  get(this: Db) {    
    return this.collection<DbUserData>('user_data')
  },
  enumerable: true, // Make it visible when iterating properties
  configurable: true, // Allow redefining if needed
})