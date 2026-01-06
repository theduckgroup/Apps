import express from 'express'
import { AnyBulkWriteOperation, BulkWriteResult, ObjectId } from 'mongodb'
import createHttpError from 'http-errors'
import { subMonths } from 'date-fns'

import eventHub from './event-hub'
import { client, getDb } from 'src/db'
import { DbInvStore } from '../db/DbInvStore'
import { DbInvStock } from '../db/DbInvStock'
import { DbInvStockAdjustment } from '../db/DbInvStockAdjustment'
import { authorizeUser, authorizeAdmin } from 'src/auth/authorize'
import { UpdateStoreCatalogBodySchema, UpdateStockBodySchema } from './schemas'
import logger from 'src/logger'
import '../db/Db+collections'
import { jsonifyMongoId } from 'src/utils/mongodb-utils'
import { getUserRoles, Roles } from 'src/utils/user-extensions'
import env from 'src/env'

// Admin router

const adminRouter = express.Router()
adminRouter.use(authorizeAdmin)

// Gets stores meta.
adminRouter.get('/stores/meta', async (req, res) => {
  const db = await getDb()

  const dbStores = await db.collection_inv_stores.find({}).toArray()

  const vendors = dbStores.map(x => ({
    id: x._id.toString(),
    name: x.name,
  }))

  res.send(vendors)
})

// Updates a store's catalog.
adminRouter.put('/stores/:storeId/catalog', async (req, res) => {
  const storeId = req.params.storeId

  // Body

  const { data, error: schemaError } = UpdateStoreCatalogBodySchema.safeParse(req.body)

  if (schemaError) {
    logger.error(schemaError)
    throw createHttpError(400)
  }

  const { items, sections } = data

  // Valid items & sections

  const itemIDs = new Set(items.map(x => x.id))

  for (const section of sections) {
    for (const row of section.rows) {
      if (!itemIDs.has(row.itemId)) {
        throw createHttpError(400, `Section row's item ID ${row.itemId} does not exist in items`)
      }
    }
  }

  // Update db

  const session = client.startSession()

  try {
    await session.withTransaction(async () => {
      const db = await getDb()

      const dbStore = await db.collection_inv_stores.findOne(
        { _id: new ObjectId(storeId) },
        { session }
      )

      if (!dbStore) {
        throw createHttpError(404, `Store ${storeId} not found`)
      }

      const dbStock = await db.collection_inv_stock.findOne(
        { storeId },
        { session }
      )

      if (!dbStock) {
        throw createHttpError(404, `Store stock not found`)
      }

      // Update store catalog
      await db.collection_inv_stores.updateOne(
        { _id: new ObjectId(storeId) },
        {
          $set: {
            'catalog.items': items,
            'catalog.sections': sections
          }
        },
        { session }
      )

      // Synchronize stock itemAttributes with catalog items
      const existingAttrsMap = new Map(dbStock.itemAttributes.map(x => [x.itemId, x]))

      const newItemAttrs = items.map(item => ({
        itemId: item.id,
        quantity: existingAttrsMap.get(item.id)?.quantity ?? 0
      }))

      await db.collection_inv_stock.updateOne(
        { storeId },
        {
          $set: {
            itemAttributes: newItemAttrs
          }
        },
        { session }
      )
    })

  } catch (error) {
    logger.error(error)

    if (error instanceof createHttpError.HttpError) {
      throw error
    }

    throw createHttpError(500)

  } finally {
    await session.endSession()
  }

  eventHub.emitStoreChanged(storeId)

  res.send()
})

// Gets stock.
adminRouter.get('/stores/:storeId/stock', async (req, res) => {
  const storeId = req.params.storeId

  if (!storeId) {
    throw createHttpError(400, `id is missing`)
  }

  const db = await getDb()

  const dbStock = await db.collection_inv_stock.findOne({ storeId })

  if (!dbStock) {
    throw createHttpError(500, 'Store stock not found')
  }

  const stock = jsonifyMongoId(dbStock)

  // console.info(`! response = ${JSON.stringify(responseVendor)}`)

  res.send(stock)
})

// Gets stock adjustment history.
adminRouter.get('/stores/:storeId/stock/adjustments', async (req, res) => {
  const storeId = req.params.storeId

  if (!storeId) {
    throw createHttpError(400, 'storeId is missing')
  }

  const db = await getDb()

  const history = await db.collection_inv_stockAdjustments
    .find({ storeId })
    .sort({ timestamp: -1 })
    .toArray()

  const response = history.map(record => jsonifyMongoId(record))

  res.send(response)
})

// User router

const userRouter = express.Router()
userRouter.use(authorizeUser)

// Gets stock adjustments metadata by user.
userRouter.get('/stores/:storeId/stock/adjustments/meta/by-user/:userId', async (req, res) => {
  const { storeId, userId } = req.params

  // Verify that userId matches current user
  if (req.user!.id !== userId) {
    throw createHttpError(403, 'Not permitted to view other users\' adjustments')
  }

  const db = await getDb()

  const adjustments = await db.collection_inv_stockAdjustments
    .find({
      storeId,
      'user.id': userId,
      timestamp: {
        $gte: subMonths(new Date(), 6)
      }
    })
    .sort({ timestamp: -1 })
    .toArray()

  const response = adjustments.map(stockAdjustmentToMeta)

  res.send(response)
})

// Gets a specific stock adjustment by ID.
userRouter.get('/stores/:storeId/stock/adjustments/:adjustmentId', async (req, res) => {
  const { storeId, adjustmentId } = req.params

  if (!storeId) {
    throw createHttpError(400, 'storeId is missing')
  }

  if (!adjustmentId) {
    throw createHttpError(400, 'adjustmentId is missing')
  }

  const db = await getDb()

  const adjustment = await db.collection_inv_stockAdjustments.findOne({
    _id: new ObjectId(adjustmentId),
    storeId
  })

  if (!adjustment) {
    throw createHttpError(404, 'Adjustment not found')
  }

  // Authorization: user must own the adjustment OR be admin/owner
  const roles = getUserRoles(req.user!)
  const isAdmin = roles.includes(Roles.owner) || roles.includes(Roles.admin)
  const userMatched = adjustment.user.id === req.user!.id

  if (!userMatched && !isAdmin) {
    throw createHttpError(403, 'Not permitted to view this adjustment')
  }

  const response = jsonifyMongoId(adjustment)

  res.send(response)
})

// Gets store.
userRouter.get('/stores/:storeId', async (req, res) => {
  const storeId = req.params.storeId

  if (!storeId) {
    throw createHttpError(400, `id is missing`)
  }

  const db = await getDb()

  const dbStore = await db.collection_inv_stores.findOne({ _id: new ObjectId(storeId) })

  if (!dbStore) {
    throw createHttpError(404, `Store ${storeId} not found`)
  }

  // let itemAttrsMap: Map<string, DbInvStock.ItemAttributes> | undefined

  // if (withQuantity) {
  //   const stock = await db.collection_inv_stock.findOne({ storeId: new ObjectId(storeId) })

  //   if (!stock) {
  //     throw createHttpError(500, 'Store stock not found')
  //   }

  //   itemAttrsMap = new Map(stock.itemAttributes.map(x => [x.itemId, x]))
  // }

  // const response = {
  //   id: dbStore._id.toString(),
  //   name: dbStore.name,
  //   catalog: {
  //     items: dbStore.catalog.items.map(dbItem => {
  //       const attrs = itemAttrsMap?.get(dbItem.id)

  //       return {
  //         id: dbItem.id.toString(),
  //         name: dbItem.name,
  //         code: dbItem.code,
  //         quantity: attrs?.quantity
  //       }
  //     }),
  //     sections: dbStore.catalog.sections
  //   }
  // }

  const store = jsonifyMongoId(dbStore)

  // console.info(`! response = ${JSON.stringify(responseVendor)}`)

  res.send(store)
})

// Updates stock.
userRouter.post('/stores/:storeId/stock', async (req, res) => {
  const storeId = req.params.storeId

  const { data, error: bodyError } = await UpdateStockBodySchema.safeParseAsync(req.body)

  if (bodyError) {
    logger.error(bodyError)
    throw createHttpError(400)
  }

  const { changes } = data

  const session = client.startSession()

  try {
    await session.withTransaction(async () => {
      // Get store and stock

      const db = await getDb()

      const dbStore = await db.collection_inv_stores.findOne(
        { _id: new ObjectId(storeId) },
        { session }
      )
      const dbStock = await db.collection_inv_stock.findOne(
        { storeId },
        { session }
      )

      if (!dbStore || !dbStock) {
        throw createHttpError(404, `Store/stock not found`)
      }

      // Verify that item IDs are valid

      const itemIDs = new Set(changes.map(x => x.itemId))
      const storeItemIDs = new Set(dbStore.catalog.items.map(x => x.id))
      const invalidItemIDs = itemIDs.difference(storeItemIDs)

      if (invalidItemIDs.size > 0) {
        throw createHttpError(400, `Invalid item IDs: ${invalidItemIDs.values().toArray().join(', ')}`)
      }

      // Update quantities with validation

      const itemAttrs = dbStock.itemAttributes
      const itemAttrsMap = new Map(itemAttrs.map(x => [x.itemId, x]))
      const storeItemsMap = new Map(dbStore.catalog.items.map(x => [x.id, x]))

      const insufficientStockErrors: string[] = []
      const historyChanges: DbInvStockAdjustment.Change[] = []

      for (const change of changes) {
        let itemAttr = itemAttrsMap.get(change.itemId)

        if (!itemAttr) {
          itemAttr = { itemId: change.itemId, quantity: 0 }
          itemAttrs.push(itemAttr)
          itemAttrsMap.set(change.itemId, itemAttr)
        }

        const oldQuantity = itemAttr.quantity
        let newQuantity: number
        let historyChange: DbInvStockAdjustment.Change

        if ('offset' in change.quantity) {
          // Offset operation (preserve existing logic)
          const delta = change.quantity.offset.delta
          newQuantity = oldQuantity + delta

          historyChange = {
            itemId: change.itemId,
            offset: {
              delta: delta,
              oldValue: oldQuantity,
              newValue: newQuantity
            }
          }

          if (newQuantity < 0) {
            const storeItem = storeItemsMap.get(change.itemId)!
            const currentQty = oldQuantity
            const removeQty = Math.abs(delta)
            insufficientStockErrors.push(
              `- ${storeItem.name} (${storeItem.code}): ${currentQty} in stock, attempting to remove ${removeQty}`
            )
          }
        } else {
          // Set operation (new functionality)
          const setValue = change.quantity.set.value
          newQuantity = setValue

          historyChange = {
            itemId: change.itemId,
            set: {
              oldValue: oldQuantity,
              newValue: newQuantity
            }
          }

          if (newQuantity < 0) {
            const storeItem = storeItemsMap.get(change.itemId)!
            insufficientStockErrors.push(
              `- ${storeItem.name} (${storeItem.code}): cannot set negative quantity ${newQuantity}`
            )
          }
        }

        if (newQuantity >= 0) {
          itemAttr.quantity = newQuantity
          historyChanges.push(historyChange)
        }
      }

      if (insufficientStockErrors.length > 0) {
        throw createHttpError(400, `Insufficient stock for the following items:\n${insufficientStockErrors.join('\n')}`)
      }

      // Create history record
      const adjustmentRecord: DbInvStockAdjustment = {
        storeId,
        timestamp: new Date(),
        user: {
          id: req.user!.id,
          email: req.user!.email || ''
        },
        changes: historyChanges
      }

      await db.collection_inv_stockAdjustments.insertOne(adjustmentRecord, { session })

      await db.collection_inv_stock.updateOne(
        { storeId },
        {
          $set: {
            itemAttributes: itemAttrs
          }
        },
        { session }
      )
    })

  } catch (error) {
    logger.error(error)

    if (error instanceof createHttpError.HttpError) {
      throw error
    }

    throw createHttpError(500)

  } finally {
    await session.endSession()
  }

  eventHub.emitStoreChanged(storeId)

  res.send()

  // Update quantities

  // const writeOps: AnyBulkWriteOperation<DbItemQuantityRecord>[] = changes.map(change => ({
  //   updateOne: {
  //     filter: {
  //       vendorId: new ObjectId(vendorId),
  //       itemId: new ObjectId(change.itemId)
  //     },
  //     // Using array for `update` makes it an aggregation pipeline
  //     // with more flexible operators I suppose
  //     update: [
  //       {
  //         $set: {
  //           quantity: {
  //             $max: [
  //               {
  //                 $add: [
  //                   { $ifNull: ["$quantity", 0] },
  //                   change.inc
  //                 ]
  //               },
  //               0
  //             ]
  //           }
  //         }
  //       }
  //     ],
  //     upsert: true
  //   }
  // }))

  // try {
  //   const writeResult = await db.collection_itemQuantityRecords.bulkWrite(writeOps)
  //   console.info(`Bulk write done | Modified count: ${writeResult.modifiedCount} | Upserted count: ${writeResult.upsertedCount}`)

  // } catch (error) {
  //   if (error instanceof BulkWriteResult) {
  //     const writeErrors = error.getWriteErrors()

  //     let lines = [
  //       `Bulk write failed | Modified count: ${error.modifiedCount} | Upserted count: ${error.upsertedCount}`,
  //       'Errors:'
  //     ]

  //     for (const e of writeErrors) {
  //       lines.push(`- Index ${e.index}: ${e.errmsg}`)
  //     }

  //     console.error(lines.join('\n'))

  //   } else {
  //     throw error
  //   }
  // }

})

// Public router

const publicRouter = express.Router()

if (env.isLocal) {
  publicRouter.get('/mock/stores/_any', async (req, res) => {
    const db = await getDb()

    const doc = await db.collection_inv_stores.findOne()

    if (!doc) {
      throw createHttpError(404)
    }

    res.send(jsonifyMongoId(doc))

  })

  publicRouter.get('/mock/stores/_any/stock', async (req, res) => {
    const db = await getDb()

    const doc = await db.collection_inv_stock.findOne()

    if (!doc) {
      throw createHttpError(404)
    }

    res.send(jsonifyMongoId(doc))
  })

  publicRouter.get('/mock/stores/_any/stock/adjustments/meta', async (req, res) => {
    const db = await getDb()

    const store = await db.collection_inv_stores.findOne()

    if (!store) {
      throw createHttpError(404, 'No store found')
    }

    const storeId = store._id.toString()

    const adjustments = await db.collection_inv_stockAdjustments
      .find({ storeId })
      .sort({ timestamp: -1 })
      .limit(10)
      .toArray()

    const response = adjustments.map(stockAdjustmentToMeta)

    res.send(response)
  })

  publicRouter.get('/mock/stores/:storeId/stock/adjustments/_any', async (req, res) => {
    const storeId = req.params.storeId

    const db = await getDb()
    const store = await db.collection_inv_stores.findOne({ _id: new ObjectId(storeId) })

    if (!store) {
      throw createHttpError(404, 'No store found')
    }

    const adjustment = await db.collection_inv_stockAdjustments.findOne({
      storeId
    })

    if (!adjustment) {
      throw createHttpError(404, 'Adjustment not found')
    }

    res.send(jsonifyMongoId(adjustment))
  })
}

// Helper functions

function stockAdjustmentToMeta(adjustment: DbInvStockAdjustment) {
  const totalQuantityChange = adjustment.changes.reduce(
    (sum, item) => {
      if (item.offset) {
        return sum + item.offset.delta
      } else if (item.set) {
        return sum + (item.set.newValue - item.set.oldValue)
      }
      return sum
    },
    0
  )

  return {
    id: adjustment._id!.toString(),
    storeId: adjustment.storeId,
    timestamp: adjustment.timestamp,
    totalQuantityChange
  }
}

// Exported router
// Order is important -- if adminRouter is first, it will attempt to authorize

const router = express.Router()

router.use(publicRouter)
router.use(userRouter)
router.use(adminRouter)

export default router