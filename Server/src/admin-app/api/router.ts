import { User } from '@supabase/supabase-js'
import express from 'express'
import createHttpError from 'http-errors'
import z from 'zod'

import supabase from 'src/auth/supabase-client'
import { authorizeAdmin } from 'src/auth/authorize'
import eventHub from './event-hub'
import { Role, Roles, getUserName, getUserRoles } from 'src/utils/user-extensions'
import logger from 'src/logger'
import { mailer } from 'src/utils/mailer'

const router = express.Router()

router.use(authorizeAdmin)

// Get all users

router.get('/users', async (req, res) => {
  const { data: { users }, error } = await supabase.auth.admin.listUsers()

  if (error) {
    logger.error(error, `Failed to retrieve Supabase users`)
    throw createHttpError(500)
  }

  res.send(users)
})

// Get a user

router.get('/users/:id', async (req, res) => {
  const id = req.params.id
  const { data: { user }, error } = await supabase.auth.admin.getUserById(req.params.id)

  if (error) {
    logger.error(error, `Failed to retrieve user ${id}`)
    throw createHttpError(500)
  }

  res.send(user)
})

const UserMetadataSchema = z.object({
  first_name: z.string(),
  last_name: z.string()
})

const AppMetadataSchema = z.object({
  roles: z.array(z.enum([Roles.owner, Roles.admin])).max(1)
})

const CreateUserSchema = z.object({
  email: z.email(),
  password: z.string(),
  user_metadata: UserMetadataSchema,
  app_metadata: AppMetadataSchema
})

// Create user

router.post('/users', async (req, res) => {
  // Body

  const { data, error: schemaError } = CreateUserSchema.safeParse(req.body)

  if (schemaError) {
    throw createHttpError(400, z.formatError(schemaError))
  }

  // Permission

  checkRoles(getUserRoles(req.user!), data.app_metadata.roles, 'create')

  // Create user

  const { data: { user: _ }, error } = await supabase.auth.admin.createUser({
    email: data.email,
    email_confirm: true, // Confirm email automatically
    user_metadata: data.user_metadata,
    app_metadata: data.app_metadata
  })

  if (error) {
    logger.error(`Failed to create user`)
    logger.error(error)

    if (error.code == 'email_exists') {

    }
    throw createHttpError(500, error.message)
  }

  res.send()

  eventHub.emitUsersChanged()
})

// Update user

const UpdateUserSchema = z.object({
  password: z.string().optional(),
  user_metadata: UserMetadataSchema.optional(),
  app_metadata: AppMetadataSchema.optional()
})

router.patch('/users/:id', async (req, res) => {
  const { data, error: schemaError } = UpdateUserSchema.safeParse(req.body)

  if (schemaError) {
    throw createHttpError(500, z.formatError(schemaError))
  }

  // Get user

  const uid = req.params.id
  const targetUser = await getUser(req.params.id)

  // Permissions - check current roles
  checkRoles(getUserRoles(req.user!), getUserRoles(targetUser), 'update')

  // Permissions - check new roles if being updated
  if (data.app_metadata) {
    checkRoles(getUserRoles(req.user!), data.app_metadata.roles, 'update')

    // Demoting last owner check

    const currentRoles = getUserRoles(targetUser)
    const newRoles = data.app_metadata.roles
    const isDemotingOwner = currentRoles.includes(Roles.owner) && !newRoles.includes(Roles.owner)

    if (isDemotingOwner) {
      await checkLastOwner(targetUser)
    }
  }

  // Update user

  const { error } = await supabase.auth.admin.updateUserById(uid, {
    password: data.password,
    user_metadata: data.user_metadata,
    app_metadata: data.app_metadata
  })

  if (error) {
    logger.error(error, `Unable to update user`)
    throw createHttpError(500)
  }

  res.send()

  eventHub.emitUsersChanged()

  sendOwnerUpdatedEmail(req.user!, targetUser, 'updated')
})

// Delete a user

router.delete('/users/:id', async (req, res) => {
  // Get user

  const uid = req.params.id
  const targetUser = await getUser(uid)

  // Roles

  checkRoles(getUserRoles(req.user!), getUserRoles(targetUser), 'delete')

  // Deleting last owner check

  await checkLastOwner(targetUser)

  // Delete user

  const { error } = await supabase.auth.admin.deleteUser(uid, false)

  if (error) {
    logger.error(error, `Unable to delete user`)
    throw createHttpError(500)
  }

  res.send()

  eventHub.emitUsersChanged()

  sendOwnerUpdatedEmail(req.user!, targetUser, 'deleted')
})

/**
 * Check if source (current) user have permission to create/update/delete target
 * (another) user. Throws 403 if not permitted.
 */
function checkRoles(sourceRoles: Role[], targetRoles: Role[], _action: 'create' | 'update' | 'delete') {
  const source_isOwner = sourceRoles.includes('org:owner')
  const source_isAdmin = sourceRoles.includes('org:admin')
  const target_isOwner = targetRoles.includes('org:owner')
  const target_isAdmin = targetRoles.includes('org:admin')

  if (source_isOwner) {
    // Can modify owners, admins and users

  } else if (source_isAdmin) {
    // Cannot modify owners and admins
    // Can modify users

    if (target_isOwner || target_isAdmin) {
      throw createHttpError(403, 'Not Permitted')

    } else {
      // OK
    }

  } else /* User */ {
    // Cannot modify owners, admins or users

    throw createHttpError(403, 'Not Permitted')
  }
}

/**
 * Checks if a user is the last owner in the system.
 * Throws 403 if attempting to delete/demote the last owner.
 */
async function checkLastOwner(targetUser: User) {
  const targetRoles = getUserRoles(targetUser)

  if (!targetRoles.includes(Roles.owner)) {
    return
  }

  const { data: { users }, error } = await supabase.auth.admin.listUsers()

  if (error) {
    logger.error(error, 'Failed to list users for last owner check')
    throw createHttpError(500)
  }

  const ownerCount = users.filter(u => getUserRoles(u).includes(Roles.owner)).length

  if (ownerCount <= 1) {
    throw createHttpError(403, 'Cannot delete or demote the last owner')
  }
}

/**
 * Gets user from Supabase. Throws 500 if failed.
 */
async function getUser(uid: string) {
  const { data: { user }, error } = await supabase.auth.admin.getUserById(uid)

  if (error) {
    logger.error(error, `Unable to get user`)
    throw createHttpError(500)
  }

  if (!user) {
    throw createHttpError(404, `User not found`)
  }

  return user
}

function sendOwnerUpdatedEmail(currentUser: User, targetUser: User, action: string) {
  if (!getUserRoles(targetUser).includes('org:owner')) {
    return
  }

  if (currentUser.id == targetUser.id) {
    return
  }

  logger.info('Sending owner updated email')

  mailer.sendMail({
    recipients: [
      {
        name: getUserName(targetUser),
        email: targetUser.email!
      }
    ],
    subject: `Account ${action}`,
    contentHtml: `Your account has been ${action} by ${getUserName(currentUser)}`
  })
  .catch(e => {
    logger.error(e, 'Failed to send mail')
  })
}

export default router

/*
Script to add org:owner role for a user (run this in Supabase SQL Editor):

```
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('roles', jsonb_build_array('org:owner'))
where email = 'theduckgroupapp@gmail.com';
```
*/