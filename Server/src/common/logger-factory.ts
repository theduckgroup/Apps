import pino, { TransportTargetOptions } from 'pino'

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