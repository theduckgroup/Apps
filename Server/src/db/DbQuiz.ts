import { ObjectId } from 'mongodb'

export interface DbQuiz {
  _id: ObjectId
  name: string
  items: DbQuiz.Item[]
  sections: DbQuiz.Section[]
  itemsPerPage: number
}

export namespace DbQuiz {
  export type Item = ListItem | MultipleChoiceQuestion | TextInputQuestion

  export interface ListItem {
    id: ObjectId
    kind: 'list-item'
    data: {
      text: string
      subitems: Item[]
    }
  }

  export interface MultipleChoiceQuestion {
    id: ObjectId
    kind: 'multiple-choice-question'
    data: {
      question: string
      choices: string[]
      choicesPerRow: 1 | 4
    }
  }

  export interface TextInputQuestion {
    id: ObjectId
    kind: 'text-input-question'
    data: {
      question: string
    }
  }

  export interface Section {
    id: ObjectId
    name: string
    rows: {
      itemId: ObjectId
    }[]
  }
}