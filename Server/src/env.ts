// This both exports the env vars and asserts that they are defined

export default {
  // serverUrl: load('SERVER_URL'),
  // webappUrl: load('WEBAPP_URL'),
  mongodb: {
    uri: load('MONGODB_URI'),
    dbName: load('MONGODB_DB_NAME'),
  },
  supabase: {
    url: load('SUPABASE_URL'),
    key: load('SUPABASE_KEY')
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