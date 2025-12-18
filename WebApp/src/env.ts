// Export env vars and assert that they are defined

export default {
  features: {
    wsApp: import.meta.env.DEV
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

// function loadOptional(name: string): string | undefined {
//   console.info(`import.meta.env['VITE_FEATURES_WS_APP'] = ${import.meta.env[name]}`)
//   return import.meta.env[name]
// }