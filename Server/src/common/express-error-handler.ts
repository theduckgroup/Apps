/*
 ! IMPORTANT: Modify this file in Common folder.
*/

import express from 'express'

/**
Middleware that sends error details (status, message, stack) in response.

Express has a default error handler that outputs HTML (in prod) or stack (in dev) in response.
See: https://expressjs.com/en/guide/error-handling.html (the "The default error handler" section).
It is not suitable for our purpose.
*/
export default function createErrorHandler(options: Options) {
  const { logger } = options
  
  function fn(error: unknown, req: express.Request, res: express.Response, next: express.NextFunction) {
    if (!(error instanceof Error)) {
      res
        .status(500)
        .send(`Unknown error: ${JSON.stringify(error)}`)

      return
    }

    // Make error visible in console
    logger.error(error)

    // Errors created with http-errors always have status and message
    // See: https://expressjs.com/en/guide/error-handling.html
    // For other errors, simply send 500

    const status = ('status' in error && typeof error.status == 'number') ? error.status : 500

    res
      .status(status)
      .send({
        message: error.message,
        stack: error.stack,
        code: 'code' in error ? error.code : undefined
      })

    /*
    // Don't mask things as 500, not worth it for small apps and just make things more difficult
    
    if (process.env.NODE_ENV === 'development') {
      res.send({
        status: status,
        message: error.message,
        stack: error.stack
      })
  
    } else {
      res.send({
        status: status,
        message: status == 500 ? 'Internal Server Error' : error.message
      })
    }
    */
  }

  return fn
}

interface Options {
  logger: {
    error: (error: unknown) => void
  }
}