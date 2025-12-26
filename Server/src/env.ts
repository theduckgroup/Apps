// This both exports the env vars and asserts that they are defined

export default {
  // serverUrl: load('SERVER_URL'),
  nodeEnv: load('NODE_ENV'),
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