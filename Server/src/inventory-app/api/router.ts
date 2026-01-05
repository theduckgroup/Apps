import express from 'express'
import { AnyBulkWriteOperation, BulkWriteResult, ObjectId } from 'mongodb'
import createHttpError from 'http-errors'

import eventHub from './event-hub'
import { client, getDb } from 'src/db'
import { DbInvStore } from '../db/DbInvStore'
import { DbInvStoreStock } from '../db/DbInvStoreStock'
import { DbInvStoreStockChange } from '../db/DbInvStoreStockChange'
import { authorizeUser, authorizeAdmin } from 'src/auth/authorize'
import { UpdateStoreCatalogBodySchema, UpdateStockBodySchema } from './schemas'
import logger from 'src/logger'
import '../db/Db+collections'
import { jsonifyMongoId } from 'src/utils/mongodb-utils'
import { getUserRoles, Roles } from 'src/utils/user-extensions'
import env from 'src/env'

// Helper functions

function transformStoreStockChangeToMeta(change: DbInvStoreStockChange) {
  const totalQuantityChange = change.itemQuantityChanges.reduce(
    (sum, item) => sum + item.delta,
    0
  )

  return {
    id: change._id!.toString(),
    storeId: change.storeId,
    timestamp: change.timestamp,
    totalQuantityChange
  }
}

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
adminRouter.put('/store/:storeId/catalog', async (req, res) => {
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

      const dbStock = await db.collection_inv_storeStocks.findOne(
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

      await db.collection_inv_storeStocks.updateOne(
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

// Gets store stock.
adminRouter.get('/store/:storeId/stock', async (req, res) => {
  const storeId = req.params.storeId

  if (!storeId) {
    throw createHttpError(400, `id is missing`)
  }

  const db = await getDb()

  const dbStock = await db.collection_inv_storeStocks.findOne({ storeId })

  if (!dbStock) {
    throw createHttpError(500, 'Store stock not found')
  }

  const stock = jsonifyMongoId(dbStock)

  // console.info(`! response = ${JSON.stringify(responseVendor)}`)

  res.send(stock)
})

// Gets store stock change history.
adminRouter.get('/store/:storeId/stock/changes', async (req, res) => {
  const storeId = req.params.storeId

  if (!storeId) {
    throw createHttpError(400, 'storeId is missing')
  }

  const db = await getDb()

  const history = await db.collection_inv_storeStocksChanges
    .find({ storeId })
    .sort({ timestamp: -1 })
    .toArray()

  const response = history.map(record => jsonifyMongoId(record))

  res.send(response)
})

// User router

const userRouter = express.Router()
userRouter.use(authorizeUser)

// Gets store stock changes metadata by user.
userRouter.get('/store/:storeId/stock/changes/meta/by-user/:userId', async (req, res) => {
  const { storeId, userId } = req.params

  if (!storeId) {
    throw createHttpError(400, 'storeId is missing')
  }

  if (!userId) {
    throw createHttpError(400, 'userId is missing')
  }

  // Verify that userId matches current user
  if (req.user!.id !== userId) {
    throw createHttpError(403, 'Not permitted to view other users\' changes')
  }

  const db = await getDb()

  const changes = await db.collection_inv_storeStocksChanges
    .find({ storeId, 'user.id': userId })
    .sort({ timestamp: -1 })
    .toArray()

  const response = changes.map(transformStoreStockChangeToMeta)

  res.send(response)
})

// Gets a specific stock change by ID.
userRouter.get('/store/:storeId/stock/changes/:changeId', async (req, res) => {
  const { storeId, changeId } = req.params

  if (!storeId) {
    throw createHttpError(400, 'storeId is missing')
  }

  if (!changeId) {
    throw createHttpError(400, 'changeId is missing')
  }

  const db = await getDb()

  const change = await db.collection_inv_storeStocksChanges.findOne({
    _id: new ObjectId(changeId),
    storeId
  })

  if (!change) {
    throw createHttpError(404, 'Change not found')
  }

  // Authorization: user must own the change OR be admin/owner
  const roles = getUserRoles(req.user!)
  const isAdmin = roles.includes(Roles.owner) || roles.includes(Roles.admin)
  const userMatched = change.user.id === req.user!.id

  if (!userMatched && !isAdmin) {
    throw createHttpError(403, 'Not permitted to view this change')
  }

  const response = jsonifyMongoId(change)

  res.send(response)
})

// Gets store.
userRouter.get('/store/:storeId', async (req, res) => {
  const storeId = req.params.storeId

  if (!storeId) {
    throw createHttpError(400, `id is missing`)
  }

  const db = await getDb()

  const dbStore = await db.collection_inv_stores.findOne({ _id: new ObjectId(storeId) })

  if (!dbStore) {
    throw createHttpError(404, `Store ${storeId} not found`)
  }

  // let itemAttrsMap: Map<string, DbInvStoreStock.ItemAttributes> | undefined

  // if (withQuantity) {
  //   const stock = await db.collection_inv_storeStocks.findOne({ storeId: new ObjectId(storeId) })

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

// Updates store stock.
userRouter.post('/store/:storeId/stock', async (req, res) => {
  const storeId = req.params.storeId

  const { data, error: bodyError } = await UpdateStockBodySchema.safeParseAsync(req.body)

  if (bodyError) {
    logger.error(bodyError)
    throw createHttpError(400)
  }

  const { itemQuantityChanges } = data

  const session = client.startSession()

  try {
    await session.withTransaction(async () => {
      // Get store and stock

      const db = await getDb()

      const dbStore = await db.collection_inv_stores.findOne(
        { _id: new ObjectId(storeId) },
        { session }
      )
      const dbStock = await db.collection_inv_storeStocks.findOne(
        { storeId },
        { session }
      )

      if (!dbStore || !dbStock) {
        throw createHttpError(404, `Store/stock not found`)
      }

      // Verify that item IDs are valid

      const itemIDs = new Set(itemQuantityChanges.map(x => x.itemId))
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

      for (const change of itemQuantityChanges) {
        let itemAttr = itemAttrsMap.get(change.itemId)

        if (!itemAttr) {
          itemAttr = { itemId: change.itemId, quantity: 0 }
          itemAttrs.push(itemAttr)
          itemAttrsMap.set(change.itemId, itemAttr)
        }

        const newQuantity = itemAttr.quantity + change.delta

        if (newQuantity < 0) {
          const storeItem = storeItemsMap.get(change.itemId)!
          const currentQty = itemAttr.quantity
          const removeQty = Math.abs(change.delta)
          insufficientStockErrors.push(
            `- ${storeItem.name} (${storeItem.code}): ${currentQty} in stock, attempting to remove ${removeQty}`
          )
        } else {
          itemAttr.quantity = newQuantity
        }
      }

      if (insufficientStockErrors.length > 0) {
        throw createHttpError(400, `Insufficient stock for the following items:\n${insufficientStockErrors.join('\n')}`)
      }

      // Create history record
      const changeRecord: DbInvStoreStockChange = {
        storeId,
        timestamp: new Date(),
        user: {
          id: req.user!.id,
          email: req.user!.email || ''
        },
        itemQuantityChanges: itemQuantityChanges.map(change => {
          const itemAttr = itemAttrsMap.get(change.itemId)!
          return {
            itemId: change.itemId,
            delta: change.delta,
            oldQuantity: itemAttr.quantity - change.delta,
            newQuantity: itemAttr.quantity
          }
        })
      }

      await db.collection_inv_storeStocksChanges.insertOne(changeRecord, { session })

      await db.collection_inv_storeStocks.updateOne(
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
  publicRouter.get('/mock/store', async (req, res) => {
    const db = await getDb()

    const doc = await db.collection_inv_stores.findOne()

    if (!doc) {
      throw createHttpError(404)
    }

    res.send(jsonifyMongoId(doc))

  })

  publicRouter.get('/mock/store/stock', async (req, res) => {
    const db = await getDb()

    const doc = await db.collection_inv_storeStocks.findOne()

    if (!doc) {
      throw createHttpError(404)
    }

    res.send(jsonifyMongoId(doc))
  })

  publicRouter.get('/mock/store/stock/changes/meta', async (req, res) => {
    const db = await getDb()

    const store = await db.collection_inv_stores.findOne()

    if (!store) {
      throw createHttpError(404, 'No store found')
    }

    const storeId = store._id.toString()

    const changes = await db.collection_inv_storeStocksChanges
      .find({ storeId })
      .sort({ timestamp: -1 })
      .limit(10)
      .toArray()

    const response = changes.map(transformStoreStockChangeToMeta)

    res.send(response)
  })

  publicRouter.get('/mock/store/stock/changes/:changeId', async (req, res) => {
    const changeId = req.params.changeId

    if (!changeId) {
      throw createHttpError(400, 'changeId is missing')
    }

    const db = await getDb()

    const change = await db.collection_inv_storeStocksChanges.findOne({
      _id: new ObjectId(changeId)
    })

    if (!change) {
      throw createHttpError(404, 'Change not found')
    }

    res.send(jsonifyMongoId(change))
  })
}

// Exported router
// Order is important -- if adminRouter is first, it will attempt to authorize

const router = express.Router()

router.use(publicRouter)
router.use(userRouter)
router.use(adminRouter)

export default router