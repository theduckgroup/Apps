import { z } from 'zod'

import { WsTemplateSchema } from './WsTemplateSchema'

const WsReportSchema = z.strictObject({
  template: WsTemplateSchema,
  user: z.strictObject({
    id: z.string(),
    name: z.string(),
    email: z.string()
  }),
  date: z.iso.datetime(),
  suppliersData: z.array(
    z.strictObject({
      supplierId: z.string(),
      amount: z.number(),
      gst: z.number(),
    })
  ),
  customSuppliersData: z.array(
    z.strictObject({
      name: z.string(),
      amount: z.number(),
      gst: z.number()
    })
  )
})

export { WsReportSchema }