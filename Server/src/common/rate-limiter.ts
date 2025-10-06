/*
 IMPORTANT: Modify this in Common.
 */

import rateLimit from 'express-rate-limit'

export default function createRateLimiter(kind?: 'login' | 'password_reset' | 'default') {
  if (!kind) {
    return rateLimit({
      windowMs: 1 * 60 * 1000, // 1 minute
      limit: 120,
      standardHeaders: 'draft-8',
      legacyHeaders: false
    })
  }

  switch (kind) {
    case 'login':
      return rateLimit({
        windowMs: 60 * 60 * 1000, // 1 hour
        limit: 12, // Number of requests per window
        standardHeaders: 'draft-8',
        legacyHeaders: false, // Disable the `X-RateLimit-*` headers,
        message: 'Too many attempts'
      })

    case 'password_reset':
      return rateLimit({
        windowMs: 24 * 60 * 60 * 1000, // 1 day
        limit: 6,
        standardHeaders: 'draft-8',
        legacyHeaders: false,
        message: 'Too many attempts'
      })
  }

  throw new Error(`Invalid rate limiter kind '${kind}'`)
}
