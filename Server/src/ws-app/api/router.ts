import express from 'express'
import { ObjectId } from 'mongodb'
// import React from 'react'
// import ReactDOMServer from 'react-dom/server'
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
import { DbWsTemplate } from '../db/DbWsTemplate'
import { DbWsReport } from '../db/DbWsReport'
import '../db/Db+collections'

// Admin router

const adminRouter = express.Router()

adminRouter.use(authorizeAdmin)

adminRouter.get('/templates', async (req, res) => {
  const db = await getDb()

  const dbTemplates = await db.collection_wsTemplates.find({}).toArray()

  interface WsTemplateMetadata {
    id: string
    code: string
    supplierCount: number
  }

  const data: WsTemplateMetadata[] = dbTemplates.map(dbQuiz => {
    return {
      id: dbQuiz._id.toString(),
      name: dbQuiz.name,
      code: dbQuiz.code,
      supplierCount: dbQuiz.sections.map(x => x.rows.length).reduce((x, y) => x + y, 0)
    }
  })

  res.send(data)
})

adminRouter.get('/template/:id', async (req, res) => {
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

adminRouter.put('/template/:id', async (req, res) => {
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

  eventHub.emitQuizzesChanged()
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

  eventHub.emitQuizzesChanged()
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
    const diffErrors = diff1.map(x => `Row item IDs not found: ${x}`)
    errors.push(...diffErrors)
  }

  const diff2 = [...supplierIDs].filter(x => !rowSupplierIDs.has(x))

  if (diff2.length > 0) {
    const diffErrors = diff2.map(x => `Item IDs not used in rows: ${x}`)
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

  const dbQuiz = await db.collection_quizzes.findOne({
    code: code
  })

  if (!dbQuiz) {
    throw createHttpError(400, 'Document not found')
  }

  const quiz = normalizeId(dbQuiz)

  res.send(quiz)
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
    submittedDate: new Date(data.submittedDate)
  }

  const insertResult = await db.collection_wsReports.insertOne(doc)
  const docId = insertResult.insertedId

  res.send()

  const recipients: mailer.Recipient[] = doc.template.emailRecipients.map(x => ({
    name: '',
    email: x
  }))

  mailer.sendMail({
    recipients: recipients,
    subject: `${doc.template.name} submitted`,
    contentHtml: quizResponseNotificationMailHtml(doc.template.name, docId)

  })
})

function quizResponseNotificationMailHtml(quizName: string, docId: ObjectId) {
  const htmlDoctype = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'

  const html = `
<p>
${quizName} has been submitted.
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

  const dbQuiz = await db.collection_quizzes.findOne({
    code: 'MAIN'
  })

  if (!dbQuiz) {
    throw createHttpError(400, 'Document not found')
  }

  const resQuiz = normalizeId(dbQuiz)
  
  res.send(resQuiz)
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