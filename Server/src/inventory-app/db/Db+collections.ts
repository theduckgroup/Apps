import { Db } from 'mongodb'
import { DbInvStore } from './DbInvStore'
import { DbInvStock } from './DbInvStock'
import { DbInvStockChange } from './DbInvStockChange'

declare module 'mongodb' {
  interface Db {
    collection_inv_stores: Collection<DbInvStore>
    collection_inv_stocks: Collection<DbInvStock>
    collection_inv_stockChanges: Collection<DbInvStockChange>
  }
}

Object.defineProperty(Db.prototype, 'collection_inv_stores', {
  get(this: Db) {
    return this.collection<DbInvStore>('inv_stores')
  },
  enumerable: true, // Make it visible when iterating properties
  configurable: true, // Allow redefining if needed
})

Object.defineProperty(Db.prototype, 'collection_inv_stocks', {
  get(this: Db) {    
    return this.collection<DbInvStock>('inv_stocks')
  },
  enumerable: true,
  configurable: true,
})

Object.defineProperty(Db.prototype, 'collection_inv_stockChanges', {
  get(this: Db) {
    return this.collection<DbInvStockChange>('inv_stock_changes')
  },
  enumerable: true,
  configurable: true,
})
