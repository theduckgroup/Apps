import { z } from 'zod'

// Metadata

const MetadataSchema = z.object({
  id: z.string(),
  name: z.string(),
  code: z.string(),
  emailRecipients: z.array(z.email())
})

// Body

const SupplierSchema = z.strictObject({
  id: z.string(),
  name: z.string(),
  gstMethod: z.enum(['notApplicable', 'tenPercent', 'input'])
})

const SectionSchema = z.strictObject({
  id: z.string(),
  name: z.string(),
  rows: z.array(
    z.strictObject({
      supplierId: z.string(),
    })
  ),
})

const BodySchema = z.strictObject({
  suppliers: z.array(SupplierSchema),
  sections: z.array(SectionSchema),
})

// Schema

const Schema = z.strictObject({
  ...MetadataSchema.shape, // Need this shape thing!
  ...BodySchema.shape
})

export {
  MetadataSchema as WsTemplateMetadataSchema,
  BodySchema as WsTemplateBodySchema,
  Schema as WsTemplateSchema
}