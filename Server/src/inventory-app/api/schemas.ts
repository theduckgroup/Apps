import { z } from 'zod'

export const UpdateStoreCatalogBodySchema = z.object({
  items: z.array(
    z.object({
      id: z.string(),
      name: z.string(),
      code: z.string(),
    })
  ),
  sections: z.array(
    z.object({
      id: z.string(),
      name: z.string(),
      rows: z.array(
        z.object({
          itemId: z.string(),
        })
      ),
    })
  ),
})

export type UpdateStoreCatalogBody = z.infer<typeof UpdateStoreCatalogBodySchema>

// Update stock body

export const UpdateStockBodySchema = z.object({
  itemQuantityChanges: z.array(
    z.object({
      itemId: z.string(),
      delta: z.number().int()
    })
  ),
})

export type UpdateStockBody = z.infer<typeof UpdateStockBodySchema>