import express from 'express'
import { ObjectId } from 'mongodb'
import createHttpError from 'http-errors'
import z from 'zod'

import env from 'src/env'
import eventHub from './event-hub'
import { getDb } from 'src/db'
import { authorizeUser, authorizeAdmin } from 'src/auth/authorize'
import { DbQuizResponse } from '../db/DbQuizResponse'
import { QuizSchema } from './QuizSchema'
import QuizResponseSchema from './QuizResponseSchema'
import logger from 'src/logger'
import { sendQuizResponseEmail, generateQuizResponseEmail } from './quiz-response-email'
import { jsonifyMongoId } from 'src/utils/mongodb-utils'

type QuizSchemaInferredType = z.infer<typeof QuizSchema>
type QuizResponseSchemaInferredType = z.infer<typeof QuizResponseSchema>

// Admin router

const adminRouter = express.Router()

adminRouter.use(authorizeAdmin)

adminRouter.get('/quizzes', async (req, res) => {
  const db = await getDb()

  const dbQuizzes = await db.collection_qz_quizzes.find({}).toArray()

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

adminRouter.put('/quiz/:id', async (req, res) => {
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

  await db.collection_qz_quizzes.findOneAndUpdate({
    _id: new ObjectId(id)
  }, {
    $set: doc
  }, {
    upsert: true
  })

  res.send()

  eventHub.emitQuizzesChanged()
})

adminRouter.delete('/quiz/:id', async (req, res) => {
  const id = req.params.id
  const db = await getDb()

  await db.collection_qz_quizzes.deleteOne({
    _id: new ObjectId(id)
  })

  res.send()

  eventHub.emitQuizzesChanged()
})

adminRouter.post('/quiz/:id/duplicate', async (req, res) => {
  const id = req.params.id

  const db = await getDb()

  const dbQuiz = await db.collection_qz_quizzes.findOne({
    _id: new ObjectId(id)
  })

  if (!dbQuiz) {
    throw createHttpError(400, 'Document not found')
  }

  dbQuiz._id = new ObjectId()
  dbQuiz.name = `${dbQuiz.name} Copy`
  dbQuiz.code = ''

  await db.collection_qz_quizzes.insertOne(dbQuiz)

  res.send()

  eventHub.emitQuizzesChanged()
})

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

// User router

const userRouter = express.Router()

userRouter.use(authorizeUser)

userRouter.get('/quiz/:id', async (req, res) => {
  const id = req.params.id

  const db = await getDb()

  const dbQuiz = await db.collection_qz_quizzes.findOne({
    _id: new ObjectId(id)
  })

  if (!dbQuiz) {
    throw createHttpError(400, 'Document not found')
  }

  const quiz = jsonifyMongoId(dbQuiz)

  // Fix data
  // TODO: Remove

  /*
  for (const item of quiz.items) {
    if (item.kind == 'textInputItem') {
      if (!item.data.layout) {
        item.data.layout = 'stack'
      }
    }

    if (item.kind == 'listItem') {
      for (const subitem of item.data.items) {
        if (subitem.kind == 'textInputItem') {
          if (!subitem.data.layout) {
            subitem.data.layout = 'stack'
          }
        }
      }
    }
  }
  */

  res.send(quiz)
})

// TODO: Remove
userRouter.get('/quiz' /* ?code=XYZ */, async (req, res) => {
  const code = req.query.code

  if (!code) {
    throw createHttpError(400, 'Missing required query parameter: code')
  }

  const db = await getDb()

  const dbQuiz = await db.collection_qz_quizzes.findOne({ code })

  if (!dbQuiz) {
    throw createHttpError(400, 'Document not found')
  }

  const quiz = jsonifyMongoId(dbQuiz)

  res.send(quiz)
})

userRouter.post('/quiz-response/submit', async (req, res) => {
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

  const insertResult = await db.collection_qz_quizResponses.insertOne(doc)
  const _docId = insertResult.insertedId

  res.send()

  const _ = sendQuizResponseEmail(doc)
})

// async function quizResponseNotificationMailHtml(quizResponse: QuizResponseSchemaInferredType, docId: ObjectId) {
//   const templatePath = path.join(__dirname, 'email-template.html')
//   let html = await fs.readFile(templatePath, 'utf-8')
//   const formattedDate = formatInTimeZone(new Date(), 'Australia/Sydney', 'EEEE, MMM d, yyyy, h:mm a')
//   const viewUrl = `${env.webappUrl}/fohtest/view/${docId.toString()}`

//   html = html
//     .replace(`{quizName}`, quizResponse.quiz.name)
//     .replace(`{respondentName}`, quizResponse.respondent.name)
//     .replace(`{respondentStore}`, quizResponse.respondent.store)
//     .replace(`{timestamp}`, formattedDate)
//     .replace(`{viewUrl}`, viewUrl)

//   return html
// }

// Public router

const publicRouter = express.Router()

if (env.nodeEnv == 'development') {
  publicRouter.get('/mock/quiz', async (req, res) => {
    const db = await getDb()

    const dbQuiz = await db.collection_qz_quizzes.findOne({ code: 'FOH_STAFF_KNOWLEDGE' })

    if (!dbQuiz) {
      throw createHttpError(404)
    }

    const resQuiz = jsonifyMongoId(dbQuiz)
    console.info(`id = ${resQuiz.id}`)

    res.send(resQuiz)
  })

  publicRouter.get('/mock/quiz-response-email', async (req, res) => {
    const db = await getDb()

    const doc = await db.collection_qz_quizResponses.findOne({}, { sort: { 'submittedDate': -1 } })

    if (!doc) {
      throw createHttpError(404)
    }

    const html = await generateQuizResponseEmail(doc)

    res.send(html)
  })
}

publicRouter.get('/quiz-response/:id', async (req, res) => {
  const db = await getDb()

  const doc = await db.collection_qz_quizResponses.findOne({
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

// Exported router
// Order is important -- if adminRouter is first, it will attempt to authorize

const router = express.Router()

router.use(publicRouter)
router.use(userRouter)
router.use(adminRouter)

export default router