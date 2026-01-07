import { Request, Response, NextFunction } from 'express'
import createHttpError from 'http-errors'
import { User } from '@supabase/supabase-js'
import supabase from './supabase-client'
import { getUserRoles, Roles } from 'src/utils/user-extensions'

/**
 * Middleware that authorizes user.
 *
 * If authorization is successful, `req.user` is set to the authorized user.
 */
export async function authorizeUser(req: Request, _res: Response, next: NextFunction) {
  await authorizeImpl(req)
  next()
}

/**
 * Middleware that authorizes user and checks for owner or admin roles.
 */
export async function authorizeAdmin(req: Request, _res: Response, next: NextFunction) {
  await authorizeImpl(req)

  const roles = getUserRoles(req.user!)
  const authorized = roles.includes(Roles.owner) || roles.includes(Roles.admin)

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

  const { data, error } = await supabase.auth.getClaims(jwt)

  if (error) {
    throw createHttpError(401, `Invalid JWT: ${error.message}`)
  }

  if (!data || !data.claims) {
    // Handle the case where no session/claims were found (the null/null scenario)
    throw createHttpError(401, `No active session found`)
  }

  const claims = data.claims

  req.user = {
    id: claims.sub,
    email: claims.email,
    app_metadata: claims.app_metadata!,
    user_metadata: claims.user_metadata!,
    aud: 'authenticated', // Fake data to conform to User
    created_at: "2000-01-01T00:00:00.000000Z", // Fake data to conform to User
  } 

  // For testing
  // const { data: supabaseUser } = await supabase.auth.getUser(jwt)
  // console.info(`Supabase user = ${JSON.stringify(supabaseUser.user)}`)
}

declare global {
  namespace Express {
    interface Request {
      user: User | null
    }
  }
}

// Example supabase user:
/*
{
  "id": "2ae3754b-c4ff-4548-923b-0181943937cc",
  "aud": "authenticated",
  "role": "authenticated",
  "email": "theduckgroupapp@gmail.com",
  "email_confirmed_at": "2025-10-05T02:10:27.799678Z",
  "phone": "",
  "confirmed_at": "2025-10-05T02:10:27.799678Z",
  "last_sign_in_at": "2026-01-06T06:00:35.78163Z",
  "app_metadata": {
    "provider": "email",
    "providers": [
      "email"
    ],
    "roles": [
      "org:owner"
    ]
  },
  "user_metadata": {
    "email_verified": true,
    "first_name": "The Duck Group App",
    "last_name": ""
  },
  "identities": [
    {
      "identity_id": "b55318cd-fbc2-44dc-9b7e-4b8034bceef4",
      "id": "2ae3754b-c4ff-4548-923b-0181943937cc",
      "user_id": "2ae3754b-c4ff-4548-923b-0181943937cc",
      "identity_data": {
        "email": "theduckgroupapp@gmail.com",
        "email_verified": false,
        "phone_verified": false,
        "sub": "2ae3754b-c4ff-4548-923b-0181943937cc"
      },
      "provider": "email",
      "last_sign_in_at": "2025-10-05T02:10:27.786297Z",
      "created_at": "2025-10-05T02:10:27.787263Z",
      "updated_at": "2025-10-05T02:10:27.787263Z",
      "email": "theduckgroupapp@gmail.com"
    }
  ],
  "created_at": "2025-10-05T02:10:27.768363Z",
  "updated_at": "2026-01-07T11:59:57.402089Z",
  "is_anonymous": false
}
*/
/*
Can also do:

declare module 'express' {
  interface Request { ... }
}

But this breaks ESLint type checking.
*/
