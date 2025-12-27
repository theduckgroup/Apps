import { ObjectId } from 'mongodb'

export interface DbInvStoreStock {
  _id: ObjectId
  storeId: ObjectId
  name: string
  itemAttributes: DbInvStoreStock.ItemAttributes[]
}

export namespace DbInvStoreStock {
  export interface ItemAttributes {
    itemId: string
    quantity: number
  }
}