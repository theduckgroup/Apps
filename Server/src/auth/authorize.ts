import { Request, Response, NextFunction } from 'express'
import createHttpError from 'http-errors'
import jwt, { TokenExpiredError } from 'jsonwebtoken'
import { AxiosError } from 'axios'

import env from 'src/env'
import supabase from './supabase-client'
import { User } from '@supabase/supabase-js'

/**
 * Middleware that authorizes user.
 * 
 * If authorization is successful, `req.user` is set to the authorized user.
 */
export default async function authorize(req: Request, res: Response, next: NextFunction) {
  await authorizeImpl(req)
  next()
}

/**
 * Middleware that authorizes user and checks for owner or admin roles.
 */
export async function authorizeAdmin(req: Request, res: Response, next: NextFunction) {
  await authorizeImpl(req)

  // const roles = req.auth!.roles
  const roles: string[] = []

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

  const userResponse = (await supabase.auth.getUser(jwt))
  
  if (userResponse.error) {
    throw createHttpError(401, `Invalid JWT: ${userResponse.error.message}`)
  }
  
  req.user = userResponse.data.user
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
