// This both exports the env vars and asserts that they are defined

export default {
  features: {
    wsApp: loadOptional('VITE_FEATURES_WS_APP') ? true : false,
  }
}

/// Loads a string from `process.env` and asserts that it is defined.
// function load(name: string): string {
//   const value = process.env[name]

//   if (!value) {
//     throw new Error(`Undefined env: ${name}`)
//   }

//   return value
// }

function loadOptional(name: string): string | undefined {
  return import.meta.env[name]
}