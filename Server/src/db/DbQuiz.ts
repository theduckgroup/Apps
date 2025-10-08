import { ObjectId } from 'mongodb'

export interface DbQuiz {
  _id: ObjectId
  name: string
  code: string
  itemsPerPage: number
  items: DbQuiz.Item[]
  sections: DbQuiz.Section[]
}

export namespace DbQuiz {
  export type Item = ListItem | SelectedResponseItem | TextInputItem

  export interface ListItem {
    id: string
    kind: 'listItem'
    data: {
      prompt: string
      items: Item[]
    }
  }

  export interface SelectedResponseItem {
    id: string
    kind: 'selectedResponseItem'
    data: {
      prompt: string
      options: {
        id: string
        value: string
      }[]
    }
  }

  export interface TextInputItem {
    id: string
    kind: 'textInputItem'
    data: {
      prompt: string
    }
  }

  export interface Section {
    id: string
    name: string
    rows: {
      itemId: string
    }[]
  }
}