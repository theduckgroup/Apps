import { z } from "zod"

const SelectedResponseItem = z.strictObject({
  kind: z.literal("selectedResponseItem"),
  id: z.string(),
  data: z.strictObject({
    prompt: z.string(),
    options: z.array(
      z.strictObject({
        id: z.string(),
        value: z.string(),
      })
    ),
  }),
})

const TextInputItem = z.strictObject({
  kind: z.literal("textInputItem"),
  id: z.string(),
  data: z.strictObject({
    prompt: z.string(),
  }),
})

const ListItem = z.strictObject({
  kind: z.literal("listItem"),
  id: z.string(),
  data: z.strictObject({
    prompt: z.string(),
    // recursive definition: items contains other Items
    items: z.array(
      z.discriminatedUnion("kind", [
        SelectedResponseItem,
        TextInputItem,
      ])
    )
  }),
})

const SectionSchema = z.strictObject({
  id: z.string(),
  name: z.string(),
  rows: z.array(
    z.strictObject({
      itemId: z.string(),
    })
  ),
})

export default z.strictObject({
  id: z.string(),
  name: z.string(),
  code: z.string(),
  itemsPerPage: z.number().int(),
  items: z.array(
    z.discriminatedUnion("kind", [
      SelectedResponseItem,
      TextInputItem,
      ListItem
    ])
  ),
  sections: z.array(SectionSchema),
})