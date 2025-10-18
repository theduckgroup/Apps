import 'dotenv/config'

import express from 'express'
import { createServer } from 'http'
import compression from 'compression'
import createHttpError from 'http-errors'
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

// Help App
// To test, use localhost:8021 (NOT 8022 due to Vite proxy)

import helpAppRouter from './help-app/router'

app.use((req, res, next) => {
  let isHelpSubdomain = req.hostname == 'help.theduckgroup.com.au'

  if (env.simulateHelpSubdomain) {
    isHelpSubdomain = true
  }

  if (isHelpSubdomain) {
    return helpAppRouter(req, res, next)
  }

  next()
})

// API

import quizAppRouter from './quiz-app/api/router'
app.use('/api/quiz-app', quizAppRouter)

import adminAppRouter from './admin-app/api/router'
app.use('/api/admin', adminAppRouter)

import resetPasswordRouter from './auth/reset-password-router'
app.use('/api/reset-password', resetPasswordRouter)

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