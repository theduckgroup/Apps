import { ObjectId } from 'bson'

export interface InvStoreStock {
  id: string
  storeId: string
  itemAttributes: InvStoreStock.ItemAttributes[]
}

export namespace InvStoreStock {
  export interface ItemAttributes {
    itemId: string
    quantity: number
  }
}