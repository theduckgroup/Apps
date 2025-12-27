import { Db } from 'mongodb'
import { DbInvStore } from './DbInvStore';
import { DbInvStoreStock } from './DbInvStoreStock';

declare module 'mongodb' {
  interface Db {
    collection_inv_stores: Collection<DbInvStore>
    collection_inv_storeStocks: Collection<DbInvStoreStock>   
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
    return this.collection<DbInvStoreStock>('inv_storeStocks')
  },
  enumerable: true,
  configurable: true,
})
