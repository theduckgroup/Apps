import express from 'express'
import createHttpError from 'http-errors'
import logger from 'src/logger'

import env from 'src/env'
import supabase from './supabase-client'
import { getUserRoles } from 'src/utils/user-extensions'

const router = express.Router() // Public

router.post('/', async (req, res) => {
  // Validate query

  const email = req.query.email

  if (typeof (email) != 'string') {
    throw createHttpError(404)
  }

  // Retrieve user

  const { data: { users }, error: listError } = await supabase.auth.admin.listUsers()

  if (listError) {
    logger.error(listError)
    throw createHttpError(500)
  }

  const user = users.find(x => x.email?.toLowerCase() == email.toLowerCase())

  if (!user) {
    logger.error(`User with email ${email} not found`)
    await new Promise(resolve => setTimeout(resolve, 5000))
    res.send() // Fake OK
    return
  }

  // Check role

  const roles = getUserRoles(user)

  if (!roles.includes('org:owner')) {
    logger.error(`Non-owner user ${email} trying to reset email`)
    await new Promise(resolve => setTimeout(resolve, 5000))
    res.send() // Fake OK
    return
  }

  // Reset password
  // Redirect URL must be configured in Supabase (Authentication > URL Configuration)
  // For localhost, after pasting the link in browser, change 'https' to 'http'

  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${env.webappUrl}/reset-password-2`
  })

  if (error) {
    logger.error(error)
    throw createHttpError(500)
  }

  res.send()
})

export default router