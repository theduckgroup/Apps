import express from 'express'
import onHeaders from 'on-headers'
import onFinished from 'on-finished'
import * as httpStatusCodes from 'http-status-codes'

export default function createMiddleware(options: Options) {
  const { logger } = options

  function fn(req: express.Request, res: express.Response, next: express.NextFunction) {
    // Store timing data on req/res objects
    req._reqlogStartAt = Date.now()

    const message = `${req.method} ${req.originalUrl}`

    /*

    if (req.body && !_.isEmpty(req.body)) {
      const excluded = options.excludes.some(s => req.path.includes(s));

      if (!excluded) {
        const json = JSON.stringify(req.body, null, 2)
        message += `\n${json}\n`

      } else {
        message += `\n(Body not logged)`
      }
    }
    */

    logger.info(`${xClear}${message}`)

    // Record time when response headers are written to calculate elapsed time when the response is finished
    // (from https://github.com/expressjs/morgan/blob/master/index.js)

    onHeaders(res, () => {
      res._reqlogStartAt = Date.now()
    })

    onFinished(res, (_err: Error | null, res: express.Response) => {
      const elapsed = (res._reqlogStartAt ?? 0) - (req._reqlogStartAt ?? 0)
      
      const statusPhrase = httpStatusCodes.getReasonPhrase(res.statusCode)

      const statusColor = (
        res.statusCode >= 500 ? 31 // Red
        : res.statusCode >= 400 ? 33 // Yellow
        : res.statusCode >= 300 ? 36 // Cyan
        : res.statusCode >= 200 ? 32 // Green
        : 0 // No color
      )

      const xStatusColor = `\x1b[${statusColor}m`

      logger.info(`${xClear}${req.method} ${req.originalUrl} - ${xStatusColor}${res.statusCode} ${statusPhrase} ${xClear}[${elapsed} ms]`)
    })

    next()
  }

  return fn
} 

interface Options {
  // excludes: string[],
  logger: {
    info: (msg: string) => void
  }
}

const xClear = '\x1b[0m'

// Extend Express types to include our custom properties
declare module 'express-serve-static-core' {
  interface Request {
    _reqlogStartAt?: number
  }
  interface Response {
    _reqlogStartAt?: number
  }
}
