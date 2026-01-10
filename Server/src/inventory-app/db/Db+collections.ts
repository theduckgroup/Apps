import { Db } from 'mongodb'
import { DbInvStore } from './DbInvStore'
import { DbInvStock } from './DbInvStock'
import { DbInvStockAdjustment } from './DbInvStockAdjustment'

declare module 'mongodb' {
  interface Db {
    collection_inv_stores: Collection<DbInvStore>
    collection_inv_stock: Collection<DbInvStock>
    collection_inv_stockAdjustments: Collection<DbInvStockAdjustment>
  }
}

Object.defineProperty(Db.prototype, 'collection_inv_stores', {
  get(this: Db) {
    return this.collection<DbInvStore>('inv_stores')
  },
  enumerable: true, // Make it visible when iterating properties
  configurable: true, // Allow redefining if needed
})

Object.defineProperty(Db.prototype, 'collection_inv_stock', {
  get(this: Db) {    
    return this.collection<DbInvStock>('inv_stock')
  },
  enumerable: true,
  configurable: true,
})

Object.defineProperty(Db.prototype, 'collection_inv_stockAdjustments', {
  get(this: Db) {
    return this.collection<DbInvStockAdjustment>('inv_stock_adjustments')
  },
  enumerable: true,
  configurable: true,
})
