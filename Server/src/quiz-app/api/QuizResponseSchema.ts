import { z } from "zod"

import { QuizSchema } from './QuizSchema'

const SelectedResponseItemResponse = z.strictObject({
  itemKind: z.literal("selectedResponseItem"),
  id: z.string(),
  itemId: z.string(),
  data: z.strictObject({
    selectedOptions: z.array(
      z.strictObject({
        id: z.string(),
        value: z.string(),
      })
    ),
  }),
})

const TextInputItemResponse = z.strictObject({
  itemKind: z.literal("textInputItem"),
  id: z.string(),
  itemId: z.string(),
  data: z.strictObject({
    value: z.string(),
  }),
})

const ListItemResponse = z.strictObject({
  itemKind: z.literal("listItem"),
  id: z.string(),
  itemId: z.string(),
  data: z.strictObject({
    itemResponses: z.array(
      z.discriminatedUnion("itemKind", [
        SelectedResponseItemResponse,
        TextInputItemResponse
      ])
    )
  }),
})

export default z.strictObject({
  quiz: QuizSchema,
  createdDate: z.iso.datetime(),
  submittedDate: z.iso.datetime(),
  itemResponses: z.array(
    z.discriminatedUnion("itemKind", [
      SelectedResponseItemResponse,
      TextInputItemResponse,
      ListItemResponse,
    ])
  ),
  respondent: z.strictObject({
    name: z.string(),
    store: z.string(),
  }),
})
