import express from 'express'
import { ObjectId } from 'mongodb'
import React from 'react'
import ReactDOMServer from 'react-dom/server'
import createHttpError from 'http-errors'

import { getDb } from 'src/db'
import { authorizeAdmin } from 'src/auth/authorize'
import { DbQuizResponse } from '../db/DbQuizResponse'
import eventHub from './event-hub'
import { QuizSchema } from './QuizSchema'
import QuizResponseSchema from './QuizResponseSchema'
import logger from 'src/logger'
import z from 'zod'
import { mailer } from 'src/utils/mailer'
import env from 'src/env'

const privateRouter = express.Router()

privateRouter.use(authorizeAdmin)

privateRouter.get('/quizzes', async (req, res) => {
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

privateRouter.get('/quiz/:id', async (req, res) => {
  const id = req.params.id

  const db = await getDb()

  const dbQuiz = await db.collection_quizzes.findOne({
    _id: new ObjectId(id)
  })

  if (!dbQuiz) {
    throw createHttpError(400, 'Document not found')
  }

  const resQuiz = normalizeId(dbQuiz)

  res.send(resQuiz)
})

privateRouter.get('/quiz' /* ?code=XYZ */, async (req, res) => {
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

  const resQuiz = normalizeId(dbQuiz)

  res.send(resQuiz)
})

privateRouter.put('/quiz/:id', async (req, res) => {
  const id = req.params.id

  // Validate schema

  const { data, error: schemaError } = QuizSchema.safeParse(req.body)

  if (schemaError) {
    logger.error(schemaError)
    throw createHttpError(400)
  }

  if (id != data.id) {
    throw createHttpError(400, 'Inconsistent body ID')
  }

  // Validate sections & items

  validateQuiz(data)

  // Upsert

  const db = await getDb()

  const doc = {
    ...data,
    _id: new ObjectId(id),
    id: undefined
  }

  await db.collection_quizzes.findOneAndUpdate({
    _id: new ObjectId(id)
  }, {
    $set: doc
  }, {
    upsert: true
  })

  res.send()

  eventHub.emitQuizzesChanged()
})

type QuizSchemaInferredType = z.infer<typeof QuizSchema>

function validateQuiz(quiz: QuizSchemaInferredType) {
  // All items are used and each one is exactly once

  const rowItemIDs = new Set<string>()

  let errors: string[] = []

  for (const section of quiz.sections) {
    for (const row of section.rows) {
      if (rowItemIDs.has(row.itemId)) {
        errors.push(`Item ID used more than once: ${row.itemId}`)
      }

      rowItemIDs.add(row.itemId)
    }
  }

  const itemIDs = new Set(quiz.items.map(x => x.id))

  const diff1 = [...rowItemIDs].filter(x => !itemIDs.has(x))

  if (diff1.length > 0) {
    const diffErrors = diff1.map(x => `Row item IDs not found: ${x}`)
    errors.push(...diffErrors)
  }

  const diff2 = [...itemIDs].filter(x => !rowItemIDs.has(x))

  if (diff2.length > 0) {
    const diffErrors = diff2.map(x => `Item IDs not used in rows: ${x}`)
    errors.push(...diffErrors)
  }

  if (errors.length > 0) {
    throw new Error('Item ID errors:\n' + errors.map(x => `- ${x}`).join('\n'))
  }
}

privateRouter.post('/quiz-response/submit', async (req, res) => {
  const { data, error: schemaError } = QuizResponseSchema.safeParse(req.body)

  if (schemaError) {
    logger.error(schemaError)
    throw createHttpError(400)
  }

  const db = await getDb()

  const doc: DbQuizResponse = {
    ...data,
    createdDate: new Date(data.createdDate),
    submittedDate: new Date(data.submittedDate)
  }

  const insertResult = await db.collection_quizResponses.insertOne(doc)
  const docId = insertResult.insertedId

  res.send()

  const recipients: mailer.Recipient[] = doc.quiz.emailRecipients.map(x => ({
    name: '',
    email: x
  }))

  mailer.sendMail({
    recipients: recipients,
    subject: `${doc.quiz.name} submitted`,
    contentHtml: quizResponseNotificationMailHtml(doc.quiz.name, docId)

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

publicRouter.get('/mock-quiz', async (req, res) => {
  console.info(`In mock-quiz`)
  const db = await getDb()

  const dbQuiz = await db.collection_quizzes.findOne({
    code: 'FOH_STAFF_KNOWLEDGE'
  })

  if (!dbQuiz) {
    throw createHttpError(400, 'Document not found')
  }

  const resQuiz = normalizeId(dbQuiz)
  console.info(`id = ${resQuiz.id}`)

  res.send(resQuiz)
})

publicRouter.get('/quiz-response/:id', async (req, res) => {
  const db = await getDb()

  const doc = await db.collection_quizResponses.findOne({
    _id: new ObjectId(req.params.id)
  })

  if (!doc) {
    throw createHttpError(404)
  }

  const data = {
    ...doc,
    _id: undefined,
    id: doc._id.toString(),
    createdDate: doc.createdDate.toISOString(),
    submittedDate: doc.submittedDate.toISOString()
  }

  res.send(data)
})

// Helpers

function normalizeId<T extends { _id: ObjectId }>(object: T) {
  const { _id, ...rest } = object
  const obj = { ...rest, id: _id.toString() }
  return obj
}

// Exported router

const router = express.Router()

router.use(publicRouter) // Order is important
router.use(privateRouter)

export default router