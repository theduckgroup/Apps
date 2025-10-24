import { Db } from 'mongodb'
import { DbWsTemplate } from './DbWsTemplate'
import { DbWsReport } from './DbWsReport'

declare module 'mongodb' {
  interface Db {
    collection_wsTemplates: Collection<DbWsTemplate>
    collection_wsReports: Collection<DbWsReport>
  }
}

Object.defineProperty(Db.prototype, 'collection_wsTemplates', {
  get(this: Db) {
    return this.collection<DbWsTemplate>('ws_templates')
  },
  enumerable: true,
  configurable: true,
})

Object.defineProperty(Db.prototype, 'collection_wsReports', {
  get(this: Db) {
    return this.collection<DbWsTemplate>('ws_reports')
  },
  enumerable: true,
  configurable: true,
})
