import { z } from 'zod'

// Metadata

const MetadataSchema = z.object({
  id: z.string(),
  name: z.string(),
  code: z.string(),
  emailRecipients: z.array(z.string())
})

// Body

const SupplierSchema = z.object({
  id: z.string(),
  name: z.string(),
  gstMethod: z.enum(['notApplicable', '10%', 'input'])
})

const SectionSchema = z.object({
  id: z.string(),
  name: z.string(),
  rows: z.array(
    z.object({
      supplierId: z.string(),
    })
  ),
})

const BodySchema = z.object({
  suppliers: z.array(SupplierSchema),
  sections: z.array(SectionSchema),
})

// Schema

const Schema = z.object({
  ...MetadataSchema.shape, // Need this shape thing!
  ...BodySchema.shape
})

export {
  MetadataSchema as WsTemplateMetadataSchema,
  BodySchema as WsTemplateBodySchema,
  Schema as WsTemplateSchema
}