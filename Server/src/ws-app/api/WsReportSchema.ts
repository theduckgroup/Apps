import { z } from "zod"

import { WsTemplateSchema } from './WsTemplateSchema'

const WsReportSchema = z.strictObject({
  template: WsTemplateSchema,
  submittedDate: z.iso.datetime(),
  suppliers: z.array(
    z.strictObject({
      supplierId: z.string(),
      amount: z.number(),
      reference: z.string()
    })
  ),
  store: z.strictObject({
    name: z.string()
  }),
})

export { WsReportSchema }