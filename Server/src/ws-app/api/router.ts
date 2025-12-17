import express from 'express'
import { ObjectId } from 'mongodb'
import createHttpError from 'http-errors'

import { getDb } from 'src/db'
import { authorizeUser, authorizeAdmin } from 'src/auth/authorize'
import eventHub from './event-hub'
import { WsTemplateSchema } from './WsTemplateSchema'
import { WsReportSchema } from './WsReportSchema'
import logger from 'src/logger'
import z from 'zod'
import { mailer } from 'src/utils/mailer'
import env from 'src/env'
import { DbWsReport } from '../db/DbWsReport'
import '../db/Db+collections'
import { generateReportEmailHtml } from './generate-report-email'
import { formatInTimeZone } from 'date-fns-tz'

// Admin router

const adminRouter = express.Router()

adminRouter.use(authorizeAdmin)

adminRouter.get('/templates', async (req, res) => {
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

adminRouter.get('/templates/:id', async (req, res) => {
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

adminRouter.delete('/template/:id', async (req, res) => {
  const id = req.params.id
  const db = await getDb()

  await db.collection_wsTemplates.deleteOne({
    _id: new ObjectId(id)
  })

  res.send()

  eventHub.emitTemplatesChanged()
})

adminRouter.post('/template/:id/duplicate', async (req, res) => {
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

  let errors: string[] = []

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

userRouter.get('/template' /* ?code=XYZ */, async (req, res) => {
  const code = req.query.code

  if (!code) {
    throw createHttpError(400, 'Missing required query parameter: code')
  }

  const db = await getDb()

  const doc = await db.collection_wsTemplates.findOne({
    code: code
  })

  if (!doc) {
    throw createHttpError(400, 'Document not found')
  }

  const data = normalizeId(doc)

  res.send(data)
})

userRouter.post('/submit', async (req, res) => {
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

  eventHub.emitUserReportsChanged(data.user.id)

  const recipients: mailer.Recipient[] = doc.template.emailRecipients.map(x => ({
    name: '',
    email: x
  }))

  const formattedDate = formatInTimeZone(new Date(), 'Australia/Sydney', 'MMM d, h:mm a')
  const subject = `[Weekly Spending] ${data.user.name} | ${formattedDate}`
  const contentHtml = generateReportEmailHtml(doc)

  mailer.sendMail({
    recipients,
    subject,
    contentHtml
  })
})

function reportNotificationMailHtml(templateName: string, docId: ObjectId) {
  const htmlDoctype = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'

  const html = `
<p>
${templateName} has been submitted.
</p>

<p>
<a href='${env.webappUrl}/fohtest/view/${docId.toString()}'>View Test</a>
</p>
    `

  return htmlDoctype + html

  // return htmlDoctype + ReactDOMServer.renderToStaticMarkup(React.createElement(OrderEmailHtml, { order: order }, null));
}

// Public router

const publicRouter = express.Router()

publicRouter.get('/mock-template', async (req, res) => {
  const db = await getDb()

  const doc = await db.collection_wsTemplates.findOne({
    code: 'WEEKLY_SPENDING'
  })

  if (!doc) {
    throw createHttpError(400, 'Document not found')
  }

  const data = normalizeId(doc)

  res.send(data)
})

publicRouter.get('/mock-email', async (req, res) => {
  // To test: http://localhost:8021/api/ws-app/mock-email

  const db = await getDb()
  const data = await db.collection_wsReports.findOne({
    _id: new ObjectId('693ccfef2ced00e3aefada20')
  })

  if (!data) {
    res.status(500)
    return
  }

  const emailHtml = generateReportEmailHtml(data)

  res.send(emailHtml)
})

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