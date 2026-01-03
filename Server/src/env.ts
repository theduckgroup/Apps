// This both exports the env vars and asserts that they are defined

type NodeEnv = 'development' | 'production'

export default {
  // serverUrl: load('SERVER_URL'),
  nodeEnv: loadNodeEnv(),
  webappUrl: load('WEBAPP_URL'),
  simulateHelpSubdomain: loadOptional('SIMULATE_HELP_SUBDOMAIN') == 'true',
  mongodb: {
    uri: load('MONGODB_URI'),
    dbName: load('MONGODB_DB_NAME'),
  },
  supabase: {
    url: load('SUPABASE_URL'),
    key: load('SUPABASE_KEY')
  },
  zohoMailer: {
    name: load('ZOHO_MAILER_NAME'),
    username: load('ZOHO_MAILER_USERNAME'),
    password: load('ZOHO_MAILER_PASSWORD')
  },
  axiom: {
    token: load('AXIOM_TOKEN'),
    dataset: load('AXIOM_DATASET')
  }
}

/// Loads NODE_ENV and validates it's either 'development' or 'production'
function loadNodeEnv(): NodeEnv {
  const value = process.env.NODE_ENV

  if (!value) {
    throw new Error(`Undefined env: NODE_ENV`)
  }

  if (value !== 'development' && value !== 'production') {
    throw new Error(`Invalid NODE_ENV: "${value}". Must be either "development" or "production"`)
  }

  return value
}

/// Loads a string from `process.env` and asserts that it is defined.
function load(name: string): string {
  const value = process.env[name]

  if (!value) {
    throw new Error(`Undefined env: ${name}`)
  }

  return value
}

function loadOptional(name: string): string | undefined {
  return process.env[name]
}