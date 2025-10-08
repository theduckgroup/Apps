import express from 'express'
import { AnyBulkWriteOperation, BulkWriteResult, Filter, ObjectId } from 'mongodb'
import asyncHandler from 'express-async-handler'
import createHttpError from 'http-errors'

import { getDb } from 'src/db'
import { DbQuiz } from 'src/db/DbQuiz'
import eventHub from 'src/event-hub'
import authorize, { authorizeAdmin } from 'src/auth/authorize'
import validateSchema from 'src/common/validate-schema'
import { validateQuiz } from './QuizSchema'
import { DefinedError } from 'ajv'

const router = express.Router()

router.get('/quizzes', async (req, res) => {
  const db = await getDb()

  const dbQuizzes = await db.collection_quizzes.find({}).toArray()

  interface QuizMetadata {
    id: string
    code: string
    sectionCount: number
    itemCount: number
  }

  const resData: QuizMetadata[] = dbQuizzes.map(dbQuiz => {
    return {
      id: dbQuiz._id.toString(),
      name: dbQuiz.name,
      code: dbQuiz.code,
      sectionCount: dbQuiz.sections.length,
      itemCount: dbQuiz.sections.map(x => x.rows.length).reduce((x, y) => x + y, 0)
    }
  })

  res.send(resData)
})

router.get('/quiz/:id', async (req, res) => {
  const id = req.params.id

  const db = await getDb()

  const dbQuiz = await db.collection_quizzes.findOne({
    _id: new ObjectId(id)
  })

  if (!dbQuiz) {
    throw createHttpError(400, 'Document not found')
  }

  const resQuiz = {
    ...dbQuiz,
    _id: undefined,
    id: dbQuiz._id.toString()
  }

  res.send(resQuiz)
})

router.put('/quiz/:id', async (req, res) => {
  // await new Promise(resolve => setTimeout(resolve, 5000))
  // throw createHttpError(400, 'Fake error')

  const id = req.params.id

  if (!validateQuiz(req.body)) {
    const message = validateQuiz.errors!
      .map(x => {
        const error = x as DefinedError
        const message = `${error.schemaPath} → ${error.instancePath}: ${error.message}`
        return message
      })
      .join('\n')

    throw createHttpError(400, message)
  }

  if (id != req.body.id) {
    throw createHttpError(400, 'Inconsistent body ID')
  }

  const db = await getDb()

  const data = {
    ...req.body,
    _id: new ObjectId(id),
    id: undefined
  }

  await db.collection_quizzes.findOneAndUpdate({
    _id: new ObjectId(id)
  }, {
    $set: data
  }, {
    upsert: true
  })

  res.send()
})


// Gets vendor summaries (ID & name), aka "metavendors".
// router.get('/vendors', authorize, asyncHandler(async (req, res) => {
//   const db = await getDb()

//   const dbVendors = await db.collection_vendors.find({}).toArray()

//   const vendors = dbVendors.map(x => ({
//     id: x._id.toString(),
//     name: x.name,
//   }))

//   res.send(vendors)
// }))

// // Gets vendor details (summary and items + sections).
// router.get('/vendor/:vendorId', authorize, asyncHandler(async (req, res) => {
//   const vendorId = req.params['vendorId']
//   const withQuantity = !!req.query.withQuantity

//   if (!vendorId) {
//     throw createHttpError(400, `vendorId is missing`)
//   }

//   const db = await getDb()

//   const dbVendor = await db.collection_vendors.findOne({ _id: new ObjectId(vendorId) })

//   if (!dbVendor) {
//     throw createHttpError(404, `Vendor ${vendorId} not found`)
//   }

//   interface ResponseVendor {
//     id: string
//     name: string
//     items: ResponseItem[]
//     sections: {
//       id: string
//       name: string
//       rows: {
//         itemId: string
//       }[]
//     }[]
//   }

//   interface ResponseItem {
//     id: string
//     name: string
//     code: string
//     quantity?: number
//   }

//   const responseVendor: ResponseVendor = {
//     id: dbVendor._id.toString(),
//     name: dbVendor.name,
//     items: dbVendor.items.map(dbItem => ({
//       id: dbItem.id.toString(),
//       name: dbItem.name,
//       code: dbItem.code
//     })),
//     sections: dbVendor.sections.map(dbSection => ({
//       id: dbSection.id.toString(),
//       name: dbSection.name,
//       rows: dbSection.rows.map(dbItem => ({
//         itemId: dbItem.itemId.toString()
//       }))
//     }))
//   }

//   if (withQuantity) {
//     for (const item of responseVendor.items) {
//       const record = await db.collection_itemQuantityRecords.findOne({
//         vendorId: dbVendor._id,
//         itemId: new ObjectId(item.id)
//       }) as DbItemQuantityRecord | null

//       item.quantity = record?.quantity ?? 0
//     }
//   }

//   // console.info(`! response = ${JSON.stringify(responseVendor)}`)

//   res.send(responseVendor)
// }))

// // Updates a vendor's items and sections.
// router.post('/vendor/:vendorId/items', authorizeAdmin, asyncHandler(async (req, res) => {
//   // Validate body

//   const bodySchema = {
//     properties: {
//       items: {
//         elements: {
//           properties: {
//             id: { type: 'string' },
//             name: { type: 'string' },
//             code: { type: 'string' },
//           }
//         },
//       },
//       sections: {
//         elements: {
//           properties: {
//             id: { type: 'string' },
//             name: { type: 'string' },
//             rows: {
//               elements: {
//                 properties: {
//                   itemId: { type: 'string' },
//                 }
//               }
//             }
//           }
//         }
//       }
//     }
//   } as const

//   validateSchema<typeof bodySchema>(req.body, '/vendor/:vendorId/items$body', bodySchema)

//   const { items, sections } = req.body

//   // Valid items & sections

//   const itemIds = new Set(items.map(x => x.id))

//   for (const section of sections) {
//     for (const row of section.rows) {
//       if (!itemIds.has(row.itemId)) {
//         throw createHttpError(`Section row's item ID ${row.itemId} does not exist in items`)
//       }
//     }
//   }

//   // Find vendor

//   const vendorId = req.params.vendorId
//   const db = await getDb()

//   const dbVendor = await db.collection_vendors.findOne({
//     _id: new ObjectId(vendorId)
//   })

//   if (!dbVendor) {
//     throw createHttpError(400, `Vendor ${vendorId} not found`)
//   }

//   // Update vendor

//   const dbVendorItems: DbVendor.Item[] = items.map(x => ({
//     id: new ObjectId(x.id),
//     name: x.name,
//     code: x.code,
//   }))

//   const dbVendorSections: DbVendor.Section[] = sections.map(x => ({
//     id: new ObjectId(x.id),
//     name: x.name,
//     rows: x.rows.map(x => ({
//       itemId: new ObjectId(x.itemId)
//     }))
//   }))

//   dbVendor.items = dbVendorItems
//   dbVendor.sections = dbVendorSections

//   await db.collection('vendors').updateOne(
//     {
//       _id: new ObjectId(vendorId)
//     },
//     {
//       $set: {
//         items: dbVendorItems,
//         sections: dbVendorSections
//       }
//     }
//   )

//   res.send()

//   eventHub.emitVendorChange(vendorId)
// }))

// // Updates a vendor's item quantities.
// router.post('/vendor/:vendorId/item-quantities', authorize, asyncHandler(async (req, res) => {
//   const bodySchema = {
//     properties: {
//       vendorId: { type: 'string' },
//       changes: {
//         elements: {
//           properties: {
//             itemId: { type: 'string' },
//             inc: { type: 'int32' },
//           }
//         },
//       }
//     }
//   } as const

//   validateSchema<typeof bodySchema>(req.body, 'POST vendor/:vendorId/items_quantity | body', bodySchema)

//   const { vendorId, changes } = req.body

//   // Get vendor

//   const db = await getDb()

//   const dbVendor = await db.collection_vendors.findOne({ _id: new ObjectId(vendorId) })

//   if (!dbVendor) {
//     throw createHttpError(`Vendor ${vendorId} not found`)
//   }

//   // Verify that items all belong to a vendor

//   const invalidRecords = await db.collection_itemQuantityRecords.find(
//     {
//       itemId: { $in: changes.map(x => new ObjectId(x.itemId)) },
//       vendorId: { $ne: new ObjectId(vendorId) }
//     }
//   ).toArray()

//   if (invalidRecords.length > 0) {
//     throw createHttpError(`Changes contain item IDs that do not belong to given vendor ID`)
//   }

//   // Update quantities

//   const writeOps: AnyBulkWriteOperation<DbItemQuantityRecord>[] = changes.map(change => ({
//     updateOne: {
//       filter: {
//         vendorId: new ObjectId(vendorId),
//         itemId: new ObjectId(change.itemId)
//       },
//       // Using array for `update` makes it an aggregation pipeline
//       // with more flexible operators I suppose
//       update: [
//         {
//           $set: {
//             quantity: {
//               $max: [
//                 {
//                   $add: [
//                     { $ifNull: ["$quantity", 0] },
//                     change.inc
//                   ]
//                 },
//                 0
//               ]
//             }
//           }
//         }
//       ],
//       upsert: true
//     }
//   }))

//   try {
//     const writeResult = await db.collection_itemQuantityRecords.bulkWrite(writeOps)
//     console.info(`Bulk write done | Modified count: ${writeResult.modifiedCount} | Upserted count: ${writeResult.upsertedCount}`)

//   } catch (error) {
//     if (error instanceof BulkWriteResult) {
//       const writeErrors = error.getWriteErrors()

//       let lines = [
//         `Bulk write failed | Modified count: ${error.modifiedCount} | Upserted count: ${error.upsertedCount}`,
//         'Errors:'
//       ]

//       for (const e of writeErrors) {
//         lines.push(`- Index ${e.index}: ${e.errmsg}`)
//       }

//       console.error(lines.join('\n'))

//     } else {
//       throw error
//     }
//   }

//   eventHub.emitVendorChange(vendorId)

//   res.send()
// }))

export default router
