import 'dotenv/config'

// SUPABASE_DB_PASSWORD=f22T1QxzI0EdOzbq

import express from 'express'
import { createServer } from 'http'
import session from 'express-session'
import createMongoDBStore from 'connect-mongodb-session'
import compression from 'compression'
import createHttpError from 'http-errors'
import ms from 'ms'
import path from 'path'

import rateLimiter from 'src/common/rate-limiter'
import requestLogger from 'src/common/express-request-logger'
import errorHandler from 'src/common/express-error-handler'
import logger from './logger'

// Env

import env from './env'
const publicDir = path.resolve(path.join(__dirname, '../public'))

// Express

const app = express()
const server = createServer(app)

app.use(express.json())
app.use(express.urlencoded({ extended: true }))

app.use(compression())

app.use('/', requestLogger({ logger }))

app.use(rateLimiter())

// Event hub

import eventHub from './event-hub'
eventHub.init(server)

// Session

const MongoDBStore = createMongoDBStore(session)

app.use(session({
  name: 'inventory.sid',
  secret: process.env.EXPRESS_SESSION_KEY!,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV != 'local',
    httpOnly: true,
    sameSite: 'strict',
    maxAge: ms('100y'),
  },
  store: new MongoDBStore({
    uri: env.mongodb.uri,
    databaseName: env.mongodb.dbName,
    collection: 'express_sessions'
  })
}))

// Static

// Auth

// import webappAuthRouter from 'src/auth/webapp-auth-router'
// app.use('/auth/webapp', webappAuthRouter)

// import authRouter from 'src/auth/auth-router'
// app.use('/auth', authRouter)

import authorize from 'src/auth/authorize'

// API

import vendorRouter from 'src/api/quiz-router'
app.use('/api', authorize, vendorRouter)

app.use('/api/*splat', (req, res) => {
  throw createHttpError(404, `Invalid Route`)
})

// Index

app.use('/', express.static(publicDir))

app.get('/*splat', (req, res) => {
  res.sendFile(publicDir + '/index.html')
})

// Send error response

app.use(errorHandler({ logger }))

// Start server

const port = parseInt(process.env.PORT!)
server.listen(port, () => logger.info(`Listening on port ${port}`))