import express from 'express'
import { ObjectId } from 'mongodb'
import createHttpError from 'http-errors'
import z from 'zod'
import { formatInTimeZone } from 'date-fns-tz'

import env from 'src/env'
import logger from 'src/logger'
import eventHub from './event-hub'
import { getDb } from 'src/db'
import { authorizeUser, authorizeAdmin } from 'src/auth/authorize'
import { WsTemplateSchema } from './WsTemplateSchema'
import { WsReportSchema } from './WsReportSchema'
import { DbWsReport } from '../db/DbWsReport'
import '../db/Db+collections'
import { sendReportEmail, generateReportEmail } from './report-email'
import { subHours, subMonths } from 'date-fns'
import { objectIdPropertyToString } from 'src/utils/object-id-utils'
import { jsonifyMongoId } from 'src/utils/mongodb-utils'

// Admin router

const adminRouter = express.Router()

adminRouter.use(authorizeAdmin)

adminRouter.put('/templates/:id', async (req, res) => {
  const id = req.params.id

  // Validate schema

  const { data, error: schemaError } = WsTemplateSchema.safeParse(req.body)

  if (schemaError) {
    logger.error(schemaError)
    throw createHttpError(400)
  }

  if (id != data.id) {
    throw createHttpError(400, 'Inconsistent body ID')
  }

  // Validate sections & items

  validateTemplate(data)

  // Upsert

  const db = await getDb()

  const doc = {
    ...data,
    _id: new ObjectId(id),
    id: undefined
  }

  await db.collection_wsTemplates.findOneAndUpdate({
    _id: new ObjectId(id)
  }, {
    $set: doc
  }, {
    upsert: true
  })

  res.send()

  eventHub.emitTemplatesChanged()
})

adminRouter.delete('/templates/:id', async (req, res) => {
  const id = req.params.id
  const db = await getDb()

  await db.collection_wsTemplates.deleteOne({
    _id: new ObjectId(id)
  })

  res.send()

  eventHub.emitTemplatesChanged()
})

adminRouter.post('/templates/:id/duplicate', async (req, res) => {
  const id = req.params.id

  const db = await getDb()

  const doc = await db.collection_wsTemplates.findOne({
    _id: new ObjectId(id)
  })

  if (!doc) {
    throw createHttpError(400, 'Document not found')
  }

  doc._id = new ObjectId()
  doc.name = `${doc.name} Copy`
  doc.code = ''

  await db.collection_wsTemplates.insertOne(doc)

  res.send()

  eventHub.emitTemplatesChanged()
})

type WsTemplateSchemaInferredType = z.infer<typeof WsTemplateSchema>

function validateTemplate(template: WsTemplateSchemaInferredType) {
  // All items are used and each one is exactly once

  const rowSupplierIDs = new Set<string>()

  const errors: string[] = []

  for (const section of template.sections) {
    for (const row of section.rows) {
      if (rowSupplierIDs.has(row.supplierId)) {
        errors.push(`Supplier ID used more than once: ${row.supplierId}`)
      }

      rowSupplierIDs.add(row.supplierId)
    }
  }

  const supplierIDs = new Set(template.suppliers.map(x => x.id))

  const diff1 = [...rowSupplierIDs].filter(x => !supplierIDs.has(x))

  if (diff1.length > 0) {
    const diffErrors = diff1.map(x => `Row supplier IDs not found: ${x}`)
    errors.push(...diffErrors)
  }

  const diff2 = [...supplierIDs].filter(x => !rowSupplierIDs.has(x))

  if (diff2.length > 0) {
    const diffErrors = diff2.map(x => `Supplier IDs not used in rows: ${x}`)
    errors.push(...diffErrors)
  }

  if (errors.length > 0) {
    throw new Error('Item ID errors:\n' + errors.map(x => `- ${x}`).join('\n'))
  }
}

// User router

const userRouter = express.Router()

userRouter.use(authorizeUser)

userRouter.get('/templates/meta' /* Optional: ?code=XYZ */, async (req, res) => {
  const db = await getDb()

  const docs = await db.collection_wsTemplates.find({}).toArray()

  interface WsTemplateMetadata {
    id: string
    code: string
    supplierCount: number
  }

  const data: WsTemplateMetadata[] = docs.map(doc => {
    return {
      id: doc._id.toString(),
      name: doc.name,
      code: doc.code,
      supplierCount: doc.sections.map(x => x.rows.length).reduce((x, y) => x + y, 0)
    }
  })

  res.send(data)
})

userRouter.get('/templates/:id', async (req, res) => {
  const id = req.params.id

  const db = await getDb()

  const dbTemplate = await db.collection_wsTemplates.findOne({
    _id: new ObjectId(id)
  })

  if (!dbTemplate) {
    throw createHttpError(400, 'Document not found')
  }

  const data = normalizeId(dbTemplate)

  res.send(data)
})

// TODO: Remove
userRouter.get('/templates' /* ?code=XYZ */, async (req, res) => {
  const code = req.query.code

  if (!code) {
    throw createHttpError(400, 'Missing required query parameter: code')
  }

  const db = await getDb()

  const docs = await db.collection_wsTemplates
    .find({
      code
    })
    .toArray()

  const data = docs.map(doc => normalizeId(doc))

  res.send(data)
})

userRouter.get('/reports/:id', async (req, res) => {
  const db = await getDb()

  const doc = await db.collection_wsReports.findOne({
    _id: new ObjectId(req.params.id)
  })

  if (!doc) {
    throw createHttpError(404)
  }

  if (doc.user.id != req.user!.id) {
    // A user can only access their own report
    throw createHttpError(403)
  }

  res.set('Cache-Control', 'public, max-age=3600')

  res.send(normalizeId(doc))
})

userRouter.post('/submit', async (req, res) => {
  await submitImpl(req, res)
})

userRouter.post('/reports/submit', async (req, res) => {
  await submitImpl(req, res)
})

async function submitImpl(req: express.Request, res: express.Response) {
  const { data, error: schemaError } = WsReportSchema.safeParse(req.body)

  if (schemaError) {
    logger.error(schemaError)
    throw createHttpError(400)
  }

  const db = await getDb()

  const doc: DbWsReport = {
    ...data,
    date: new Date(data.date),
  }

  const insertResult = await db.collection_wsReports.insertOne(doc)
  const docId = insertResult.insertedId

  res.send()

  eventHub.emitUserReportsChanged(doc.user.id)

  const _ = sendReportEmail(doc)
}

userRouter.get('/users/:userId/reports/meta', async (req, res) => {
  const userId = req.params.userId

  if (userId != req.user!.id) {
    throw createHttpError(403)
  }

  const db = await getDb()

  const docs = await db.collection_wsReports
    .find({
      'user.id': userId,
      'date': {
        $gte: subMonths(new Date(), 6)
        // $gte: subHours(new Date(), 24)
      }
    })
    .project<DbWsReport>({
      _id: 1,
      'template.id': 1,
      'template.name': 1,
      'template.code': 1,
      user: 1,
      date: 1,
    })
    .toArray()

  // For some reason, docs is Document[] and cannot be used with `normalizeId`

  const response = docs.map(doc => jsonifyMongoId(doc))
  // docs = docs.map(doc => ({ id: doc._id, ...doc, _id: undefined }))


  res.send(response)
})

// Public router

const publicRouter = express.Router()

if (env.nodeEnv == 'development') {
  publicRouter.get('/mock-template', async (req, res) => {
    const db = await getDb()

    const doc = await db.collection_wsTemplates.findOne()

    if (!doc) {
      throw createHttpError(404, 'Template not found')
    }

    const data = normalizeId(doc)

    res.send(data)
  })

  publicRouter.get('/mock-report', async (req, res) => {
    const db = await getDb()

    const doc = await db.collection_wsReports.findOne({}, { sort: { 'date': -1 } })

    if (!doc) {
      throw createHttpError(404)
    }

    const data = normalizeId(doc)

    res.send(data)
  })

  publicRouter.get('/mock-report-email', async (req, res) => {
    // To test: http://localhost:8021/api/ws-app/mock-report-email

    const db = await getDb()
    const doc = await db.collection_wsReports.findOne({}, { sort: { 'date': -1 } })

    if (!doc) {
      throw createHttpError(404)
    }

    const emailHtml = await generateReportEmail(doc)

    res.send(emailHtml)
  })
}

// publicRouter.get('/quiz-response/:id', async (req, res) => {
//   const db = await getDb()

//   const doc = await db.collection_quizResponses.findOne({
//     _id: new ObjectId(req.params.id)
//   })

//   if (!doc) {
//     throw createHttpError(404)
//   }

//   const data = {
//     ...doc,
//     _id: undefined,
//     id: doc._id.toString(),
//     createdDate: doc.createdDate.toISOString(),
//     submittedDate: doc.submittedDate.toISOString()
//   }

//   res.send(data)
// })

// Helpers

function normalizeId<T extends { _id: ObjectId }>(object: T) {
  const { _id, ...rest } = object
  const obj = { ...rest, id: _id.toString() }
  return obj
}

// Exported router
// Order is important -- if adminRouter is first, it will attempt to authorize

const router = express.Router()

router.use(publicRouter)
router.use(userRouter)
router.use(adminRouter)

export default router