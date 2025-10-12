import express from 'express'
import { ObjectId } from 'mongodb'
import createHttpError from 'http-errors'

import { getDb } from 'src/db'
import { authorizeAdmin } from 'src/auth/authorize'
import eventHub from './event-hub'
import { validateQuiz } from './QuizSchema'
import formatSchemaErrors from 'src/utils/format-schema-errors'

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
  // await new Promise(resolve => setTimeout(resolve, 5000))
  // throw createHttpError(400, 'Fake error')

  const id = req.params.id

  if (!validateQuiz(req.body)) {
    throw createHttpError(400, formatSchemaErrors(validateQuiz.errors!))
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

  eventHub.emitQuizzesChanged()
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
  res.send(500)
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