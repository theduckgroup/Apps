import { Request, Response, NextFunction } from 'express'
import createHttpError from 'http-errors'
import { User } from '@supabase/supabase-js'
import supabase from './supabase-client'
import logger from 'src/logger'

/**
 * Middleware that authorizes user.
 * 
 * If authorization is successful, `req.user` is set to the authorized user.
 */
export async function authorizeUser(req: Request, res: Response, next: NextFunction) {
  await authorizeImpl(req)
  next()
}

/**
 * Middleware that authorizes user and checks for owner or admin roles.
 */
export async function authorizeAdmin(req: Request, _res: Response, next: NextFunction) {
  await authorizeImpl(req)

  const roles = (() => {
    const rolesData: unknown = req.user!.app_metadata.roles

    if (!Array.isArray(rolesData)) {
      logger.warn('app_metadata.roles is not an array', { rolesData })
      return []
    }

    const hasNonString = rolesData.some(r => typeof r !== 'string')
    if (hasNonString) {
      logger.warn('app_metadata.roles contains non-string elements', { rolesData })
    }

    return rolesData.filter((r): r is string => typeof r === 'string')
  })()

  const authorized = roles.includes('org:owner') || roles.includes('org:admin')

  if (!authorized) {
    throw createHttpError(403, `Not permitted`)
  }

  next()
}

async function authorizeImpl(req: Request) {
  const authHeader = req.headers['authorization']

  if (typeof authHeader != 'string') {
    throw createHttpError(401, 'No authorization')
  }

  const jwt = authHeader.split(' ')[1]

  if (!jwt) {
    throw createHttpError(401, 'Invalid authorization')
  }

  const { data, error } = (await supabase.auth.getUser(jwt))
  
  if (error) {
    throw createHttpError(401, `Invalid JWT: ${error.message}`)
  }
  
  req.user = data.user
}

declare global {
  namespace Express {
    interface Request {
      user: User | null
    }
  }
}

/*
Can also do:

declare module 'express' {
  interface Request { ... }
}

But this breaks ESLint type checking.
*/
