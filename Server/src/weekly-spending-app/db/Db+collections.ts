import { Db } from 'mongodb'
import { DbWsTemplate } from './DbWsTemplate'

declare module 'mongodb' {
  interface Db {
    collection_wsTemplates: Collection<DbWsTemplate>
  }
}

Object.defineProperty(Db.prototype, 'collection_wsTemplates', {
  get(this: Db) {
    return this.collection<DbWsTemplate>('ws_templates')
  },
  enumerable: true,
  configurable: true,
})
