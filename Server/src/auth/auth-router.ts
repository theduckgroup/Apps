import express from 'express'
import { ObjectId } from 'mongodb'
import createHttpError from 'http-errors'

import { getDb } from 'src/db'
import authorize from 'src/auth/authorize'
import { DbUserData } from 'src/db/DbUserData'
import { DbQuiz } from 'src/db/DbQuiz'
import { AxiosError } from 'axios'

const router = express.Router()

// Get current user (from req.auth)

// router.get('/user', authorize, async (req, res) => {
//   const userId = req.auth!.userId
//   let authUser: AuthServerUser

//   try {
//     authUser = (await authServer.get<AuthServerUser>(`/api/users/${userId}`)).data

//   } catch(error) {
//     if (!(error instanceof AxiosError)) {
//       throw createHttpError(500, `Auth Server Error: (Non-axios error)`)
//     }

//     throw createHttpError(500, `Auth Server Error: ${error.code}`)
//   }

//   // User data
//   // Insert if doesn't exist

//   const db = await getDb()
//   let dbUserData = await db.collection_userData.findOne({ userId: new ObjectId(userId) }) as DbUserData | null

//   if (!dbUserData) {
//     console.info(`User data not found, creating one`)

//     const dbVendor = await db.collection_vendors.findOne<DbVendor>({})

//     if (!dbVendor) {
//       throw createHttpError(400, 'Unable to create user data because there are no vendors')
//     }

//     dbUserData = {
//       userId: new ObjectId(userId),
//       defaultVendorId: dbVendor._id
//     }

//     await db.collection_userData.insertOne(dbUserData)
//   }

//   // Response

//   const user: User = {
//     ...authUser,
//     appData: {
//       defaultVendorId: dbUserData.defaultVendorId.toString()
//     }
//   }

//   res.send(user)
// })

// interface User {
//   userId: string
//   username: string
//   roles: string[]
//   profile: {
//     email: string
//     firstName: string
//     lastName: string
//   },
//   appData: {
//     defaultVendorId: string
//   }
// }

// export default router