import env from 'src/env'
import createLogger from 'src/utils/logger-factory'

export default createLogger({
  app: 'quiz',
  console: true,
  axiomConfig: {
    token: env.axiom.token,
    dataset: env.axiom.dataset
  }
})