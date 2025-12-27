import { ObjectId } from 'mongodb';

export interface DbInvStore {
  _id?: ObjectId
  name: string
  catalog: {
    items: DbInvStore.Item[]
    sections: DbInvStore.Section[]
  }
}

export namespace DbInvStore {
  export interface Item {
    id: string
    name: string
    code: string
  }

  export interface Section {
    id: string
    name: string
    rows: { itemId: string }[]
  }
}