import { ObjectId } from 'mongodb'
import { DbQuiz } from './DbQuiz'

export interface DbQuizResponse {
  // _id: ObjectId
  quiz: DbQuiz
  createdDate: Date
  submittedDate: Date
  itemResponses: DbQuizResponse.ItemResponse[]
  respondent: {
    name: string
    store: string
  }
}

export namespace DbQuizResponse {
  export type ItemResponse =
    | ListItemResponse
    | SelectedResponseItemResponse
    | TextInputItemResponse

  export interface ListItemResponse {
    itemKind: "listItem"
    data: {
      itemResponses: ItemResponse[]
    }
  }

  export interface SelectedResponseItemResponse {
    itemKind: "selectedResponseItem"
    data: {
      selectedOptions: {
        id: string
        value: string
      }[]
    }
  }

  export interface TextInputItemResponse {
    itemKind: "textInputItem"
    data: {
      value: string
    }
  }
}