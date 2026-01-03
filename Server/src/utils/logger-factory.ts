import pino, { TransportTargetOptions } from 'pino'

// Note: even though pino-pretty is included in prod dependencies, it is never used in prod
// Including it just makes code easier to write -- don't have to gate code behind env check etc
// TODO: try to fix this

export default function createLogger(options: Options) {
  const { app, console, axiomConfig } = options

  // Targets

  const prettyTargetConfig: TransportTargetOptions = {
    target: 'pino-pretty',
    options: {
      // https://github.com/pinojs/pino-pretty?tab=readme-ov-file#options
      ignore: 'app',
      customColors: 'info:blue,warn:yellow,error:red,message:white'
    }
  }

  const axiomTargetConfig: TransportTargetOptions = {
    target: '@axiomhq/pino',
    options: axiomConfig
  }

  const transportTargets = (
    console ?
      [axiomTargetConfig, prettyTargetConfig] :
      [axiomTargetConfig]
  )

  // Logger

  // pino.transport() returns ThreadStream (not exported), which is compatible with DestinationStream
  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const transport = pino.transport({ targets: transportTargets })

  return pino(
    {
      formatters: {
        bindings: (_bindings) => {
          return { app }
        },
      },
      timestamp: pino.stdTimeFunctions.isoTime
    },
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
    transport
  )
}

interface Options {
  console: boolean,
  app: string,
  axiomConfig: {
    token: string
    dataset: string
  }
}