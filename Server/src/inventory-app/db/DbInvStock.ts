import { ObjectId } from 'mongodb'

export interface DbInvStock {
  _id?: ObjectId
  storeId: string
  name: string
  itemAttributes: DbInvStock.ItemAttributes[]
}

export namespace DbInvStock {
  export interface ItemAttributes {
    itemId: string
    quantity: number
  }
}
