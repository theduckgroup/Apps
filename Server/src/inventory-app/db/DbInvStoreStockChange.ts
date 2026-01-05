import { ObjectId } from 'mongodb'

export interface DbInvStoreStockChange {
  _id?: ObjectId
  storeId: string
  timestamp: Date
  user: DbInvStoreStockChange.User
  itemQuantityChanges: DbInvStoreStockChange.ItemQuantityChange[]
}

export namespace DbInvStoreStockChange {
  export interface User {
    id: string
    email: string
  }

  export interface ItemQuantityChange {
    itemId: string
    delta: number
    oldQuantity: number
    newQuantity: number
  }
}
