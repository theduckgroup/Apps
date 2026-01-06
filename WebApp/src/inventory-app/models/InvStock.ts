import { ObjectId } from 'bson'

export interface InvStock {
  id: string
  storeId: string
  itemAttributes: InvStock.ItemAttributes[]
}

export namespace InvStock {
  export interface ItemAttributes {
    itemId: string
    quantity: number
  }
}
