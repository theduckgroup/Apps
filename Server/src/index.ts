import express from 'express'
import { createServer } from 'http'
import compression from 'compression'
import nocache from 'nocache'
import createHttpError from 'http-errors'
import path from 'path'

import rateLimiter from 'src/utils/rate-limiter'
import requestLogger from 'src/utils/express-request-logger'
import errorHandler from 'src/utils/express-error-handler'
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
app.use(requestLogger({ logger }))
app.use(rateLimiter())
app.set('trust proxy', 1) // Require for rate limiter; this is because the app runs in Docker

// Event hub

import eventHub from './event-hub'
eventHub.init(server)

// Help App
// To test, use localhost:8021 (NOT 8022 due to Vite proxy)

import helpAppRouter from './help-app/router'

app.use((req, res, next) => {
  let isHelpSubdomain = (
    req.hostname == 'help.theduckgroup.com.au' ||
    req.hostname == 'support.theduckgroup.com.au'
  )

  if (env.simulateHelpSubdomain) {
    isHelpSubdomain = true
  }

  if (isHelpSubdomain) {
    return helpAppRouter(req, res, next)
  }

  next()
})

// API

import adminAppRouter from './admin-app/api/router'
app.use('/api/admin', adminAppRouter)

import resetPasswordRouter from './auth/reset-password-router'
app.use('/api/reset-password', resetPasswordRouter)

import quizAppRouter from './quiz-app/api/router'
app.use('/api/quiz-app', quizAppRouter)

import wsAppRouter from './ws-app/api/router'
app.use('/api/ws-app', wsAppRouter)

import inventoryAppRouter from './inventory-app/api/router'
app.use('/api/inventory-app', inventoryAppRouter)

app.get('/api/info', (req, res) => {
  res.send({
    env: env.nodeEnv
  })
})

app.use('/api/*splat', (req, res) => {
  throw createHttpError(404, `Invalid Route`)
})

// Index

app.use('/', express.static(publicDir))

app.get('/*splat', nocache(), (req, res) => {
  // Disable cache control to avoid page error after deployment
  // See: https://vite.dev/guide/build#load-error-handling
  res.header('Cache-Control', 'no-store')

  res.sendFile(publicDir + '/index.html')
})

/*
// Health check for DigitalOcean App Platform
// No longer used (it uses TCP now)

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() })
})
*/

// Send error response

app.use(errorHandler({ logger }))

// Start server
// Using 0.0.0.0 is considered best practice with Dockerfile
// However when I tried it, it keeps failing with "address already in use" error!

const port = parseInt(process.env.PORT!)
server.listen(port, () => logger.info(`Listening on port ${port}`))

// Backup service

import { startBackupService } from './backup-service'
startBackupService()
