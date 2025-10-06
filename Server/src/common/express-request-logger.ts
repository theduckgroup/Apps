import express from 'express'
import onHeaders from 'on-headers'
import onFinished from 'on-finished'
import * as httpStatusCodes from 'http-status-codes'

export default function createMiddleware(options: Options) {
  const { logger } = options

  function fn(req: express.Request, res: express.Response, next: express.NextFunction) {
    const req_any: any = req
    const res_any: any = res

    req_any[key_startAt] = Date.now()

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
      res_any[key_startAt] = Date.now()
    })

    onFinished(res, (err: Error | null, res: express.Response) => {
      const elapsed = res_any[key_startAt] - req_any[key_startAt]
      
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
const key_startAt = 'reqlog_startAt'

