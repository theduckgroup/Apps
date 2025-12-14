import { z } from "zod"

// Metadata

const MetadataSchema = z.object({
  id: z.string(),
  name: z.string(),
  code: z.string(),
  emailRecipients: z.array(z.string())
})

// Body

const SelectedResponseItem = z.object({
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

const TextInputItem = z.object({
  kind: z.literal("textInputItem"),
  id: z.string(),
  data: z.object({
    prompt: z.string(),
    layout: z.enum(['inline', 'stack'])
  }),
})

const ListItem = z.object({
  kind: z.literal("listItem"),
  id: z.string(),
  data: z.object({
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

const SectionSchema = z.object({
  id: z.string(),
  name: z.string(),
  rows: z.array(
    z.object({
      itemId: z.string(),
    })
  ),
})

const BodySchema = z.object({
  items: z.array(
    z.discriminatedUnion("kind", [
      SelectedResponseItem,
      TextInputItem,
      ListItem
    ])
  ),
  sections: z.array(SectionSchema),
})

// Schema

const Schema = z.object({
  ...MetadataSchema.shape, // Need this shape thing!
  ...BodySchema.shape
})

export { 
  MetadataSchema as QuizMetadataSchema, 
  BodySchema as QuizBodySchema,
  Schema as QuizSchema
}