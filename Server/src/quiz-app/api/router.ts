import express from 'express'
import { ObjectId, WithoutId } from 'mongodb'
import createHttpError from 'http-errors'

import { getDb } from 'src/db'
import { authorizeAdmin } from 'src/auth/authorize'
import { DbQuizResponse } from '../db/DbQuizResponse'
import eventHub from './event-hub'
import QuizSchema from './QuizSchema'
import QuizResponseSchema from './QuizResponseSchema'
import logger from 'src/logger'

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

  const { data, error: schemaError } = QuizSchema.safeParse(req.body)

  if (schemaError) {
    logger.error(schemaError)
    throw createHttpError(400)
  }

  if (id != data.id) {
    throw createHttpError(400, 'Inconsistent body ID')
  }

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

  await db.collection_quizResponses.insertOne(doc)

  res.send()
})

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