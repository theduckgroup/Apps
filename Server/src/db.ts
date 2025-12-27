import { MongoClient, Db } from 'mongodb'

import env from 'src/env'
import deduplicate from 'src/common/deduplicate'

// Without these imports, there is no TypeScript error but app will crash because the extension properties are not defined
import 'src/quiz-app/db/Db+collections'

const client = new MongoClient(env.mongodb.uri)
let db: Db | undefined

export { client }

export async function getDb() {
  return await deduplicate({
    key: 'db',
    fn: () => getDbImpl()
  })
}

async function getDbImpl() {
  if (db) {
    return db
  }

  await client.connect()
  db = client.db(env.mongodb.dbName)
  await db.command({ ping: 1 })
  console.info(`Mongo db connected`)

  return db
}