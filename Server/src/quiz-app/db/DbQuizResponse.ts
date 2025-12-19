import { ObjectId } from 'mongodb'
import { DbQuiz } from './DbQuiz'

export interface DbQuizResponse {
  _id?: ObjectId
  quiz: DbQuiz
  user: {
    id: string
    email: string
    name: string
  }
  respondent: {
    name: string
    store: string
  }
  createdDate: Date
  submittedDate: Date
  itemResponses: DbQuizResponse.ItemResponse[]
}

export namespace DbQuizResponse {
  export type ItemResponse =
    | ListItemResponse
    | SelectedResponseItemResponse
    | TextInputItemResponse

  export interface ListItemResponse {
    itemKind: "listItem"
    id: string
    itemId: string
    data: {
      itemResponses: ItemResponse[]
    }
  }

  export interface SelectedResponseItemResponse {
    itemKind: "selectedResponseItem"
    id: string
    itemId: string
    data: {
      selectedOptions: {
        id: string
        value: string
      }[]
    }
  }

  export interface TextInputItemResponse {
    itemKind: "textInputItem"
    id: string
    itemId: string
    data: {
      value: string
    }
  }
}