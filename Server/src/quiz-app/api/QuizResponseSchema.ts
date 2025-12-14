import { z } from "zod"

import { QuizSchema } from './QuizSchema'

const SelectedResponseItemResponse = z.object({
  itemKind: z.literal("selectedResponseItem"),
  id: z.string(),
  itemId: z.string(),
  data: z.object({
    selectedOptions: z.array(
      z.object({
        id: z.string(),
        value: z.string(),
      })
    ),
  }),
})

const TextInputItemResponse = z.object({
  itemKind: z.literal("textInputItem"),
  id: z.string(),
  itemId: z.string(),
  data: z.object({
    value: z.string(),
  }),
})

const ListItemResponse = z.object({
  itemKind: z.literal("listItem"),
  id: z.string(),
  itemId: z.string(),
  data: z.object({
    itemResponses: z.array(
      z.discriminatedUnion("itemKind", [
        SelectedResponseItemResponse,
        TextInputItemResponse
      ])
    )
  }),
})

export default z.object({
  quiz: QuizSchema,
  user: z.object({
    id: z.string(),
    email: z.string(),
    name: z.string(),
  }),
  createdDate: z.iso.datetime(),
  submittedDate: z.iso.datetime(),
  itemResponses: z.array(
    z.discriminatedUnion("itemKind", [
      SelectedResponseItemResponse,
      TextInputItemResponse,
      ListItemResponse,
    ])
  ),
  respondent: z.object({
    name: z.string(),
    store: z.string(),
  }),
})
