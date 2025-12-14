import { z } from 'zod'

import { WsTemplateSchema } from './WsTemplateSchema'

const WsReportSchema = z.object({
  template: WsTemplateSchema,
  user: z.object({
    id: z.string(),
    email: z.string(),
    name: z.string(),
  }),
  date: z.iso.datetime(),
  suppliersData: z.array(
    z.object({
      supplierId: z.string(),
      amount: z.number(),
      gst: z.number(),
    })
  ),
  customSuppliersData: z.array(
    z.object({
      name: z.string(),
      amount: z.number(),
      gst: z.number()
    })
  )
})

export { WsReportSchema }