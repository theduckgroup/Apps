import { ObjectId } from 'mongodb'

export interface DbInvStoreStockChange {
  _id?: ObjectId
  storeId: string
  timestamp: Date
  user: DbInvStoreStockChange.User
  changes: DbInvStoreStockChange.Change[]
}

export namespace DbInvStoreStockChange {
  export interface User {
    id: string
    email: string
  }

  export interface Change {
    itemId: string
    offset?: OffsetChange
    set?: SetChange
  }

  export interface OffsetChange {
    delta: number
    oldValue: number
    newValue: number
  }

  export interface SetChange {
    oldValue: number
    newValue: number
  }
}
