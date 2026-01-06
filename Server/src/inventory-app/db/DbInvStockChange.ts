import { ObjectId } from 'mongodb'

export interface DbInvStockChange {
  _id?: ObjectId
  storeId: string
  timestamp: Date
  user: DbInvStockChange.User
  changes: DbInvStockChange.Change[]
}

export namespace DbInvStockChange {
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
