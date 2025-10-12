import { z } from "zod"

// ---------- Item Variants ----------

const SelectedResponseItemSchema = z.object({
  kind: z.literal("selectedResponseItem"),
  id: z.string(),
  data: z.object({
    prompt: z.string(),
    options: z.array(
      z.object({
        id: z.string(),
        value: z.string(),
      })
    ),
  }),
})

const TextInputItemSchema = z.object({
  kind: z.literal("textInputItem"),
  id: z.string(),
  data: z.object({
    prompt: z.string(),
  }),
})

const ListItemSchema = z.object({
  kind: z.literal("listItem"),
  id: z.string(),
  data: z.object({
    prompt: z.string(),
    // recursive definition: items contains other Items
    items: z.array(
      z.discriminatedUnion("kind", [
        SelectedResponseItemSchema,
        TextInputItemSchema,
      ])
    )
  }),
})

const ItemSchema = z.discriminatedUnion("kind", [
  SelectedResponseItemSchema,
  TextInputItemSchema,
  ListItemSchema
])

const SectionSchema = z.object({
  id: z.string(),
  name: z.string(),
  rows: z.array(
    z.object({
      itemId: z.string(),
    })
  ),
})

export default z.object({
  id: z.string(),
  name: z.string(),
  code: z.string(),
  itemsPerPage: z.number().int(),
  items: z.array(ItemSchema),
  sections: z.array(SectionSchema),
})