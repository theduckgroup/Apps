// NOT USED

import createMongoDBStore from 'connect-mongodb-session'
import session from 'express-session'
import ms from 'ms'
import env from '../env'

const MongoDBStore = createMongoDBStore(session)

export default session({
  name: 'apps.sid',
  secret: process.env.EXPRESS_SESSION_KEY!,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV != 'local',
    httpOnly: true,
    sameSite: 'strict',
    maxAge: ms('100y'),
  },
  store: new MongoDBStore({
    uri: env.mongodb.uri,
    databaseName: env.mongodb.dbName,
    collection: 'express_sessions'
  })
})