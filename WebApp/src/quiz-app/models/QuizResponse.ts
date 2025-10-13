import { Quiz } from './Quiz'

export interface QuizResponse {
  id: string
  createdDate: Date
  submittedDate: Date
  quiz: Quiz
  itemResponses: QuizResponse.ItemResponse[]
  respondent: {
    name: string
    store: string
  }
}

export type QuizResponsePayload = ReplaceFields<QuizResponse, {
  createdDate: string,
  submittedDate: string
}>

export namespace QuizResponse {
  export type ItemResponse =
    | ListItemResponse
    | SelectedResponseItemResponse
    | TextInputItemResponse

  export interface ListItemResponse {
    id: string
    itemId: string
    itemKind: "listItem"
    data: {
      itemResponses: ItemResponse[]
    }
  }

  export interface SelectedResponseItemResponse {
    id: string
    itemId: string
    itemKind: "selectedResponseItem"
    data: {
      selectedOptions: {
        id: string
        value: string
      }[]
    }
  }

  export interface TextInputItemResponse {
    id: string
    itemId: string
    itemKind: "textInputItem"
    data: {
      value: string
    }
  }
}

// Helper

type ReplaceFields<T, Replacements extends Partial<Record<keyof T, unknown>>> = {
  [K in keyof T]: K extends keyof Replacements ? Replacements[K] : T[K]
}