import { ObjectId } from 'mongodb'

export interface DbInvStockAdjustment {
  _id?: ObjectId
  storeId: string
  timestamp: Date
  user: DbInvStockAdjustment.User
  changes: DbInvStockAdjustment.Change[]
}

export namespace DbInvStockAdjustment {
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
