import { Db } from 'mongodb'
import { DbInvStore } from './DbInvStore'
import { DbInvStoreStock } from './DbInvStoreStock'
import { DbInvStoreStockChange } from './DbInvStoreStockChange'

declare module 'mongodb' {
  interface Db {
    collection_inv_stores: Collection<DbInvStore>
    collection_inv_storeStocks: Collection<DbInvStoreStock>
    collection_inv_storeStocksChanges: Collection<DbInvStoreStockChange>
  }
}

Object.defineProperty(Db.prototype, 'collection_inv_stores', {
  get(this: Db) {
    return this.collection<DbInvStore>('inv_stores')
  },
  enumerable: true, // Make it visible when iterating properties
  configurable: true, // Allow redefining if needed
})

Object.defineProperty(Db.prototype, 'collection_inv_storeStocks', {
  get(this: Db) {    
    return this.collection<DbInvStoreStock>('inv_store_stocks')
  },
  enumerable: true,
  configurable: true,
})

Object.defineProperty(Db.prototype, 'collection_inv_storeStocksChanges', {
  get(this: Db) {
    return this.collection<DbInvStoreStockChange>('inv_store_stocks_changes')
  },
  enumerable: true,
  configurable: true,
})
