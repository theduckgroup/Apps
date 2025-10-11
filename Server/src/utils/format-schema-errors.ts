import { DefinedError, ErrorObject } from 'ajv'

export default function formatSchemaErrors(errors: ErrorObject[]) {
  return errors
    .map(x => {
      const error = x as DefinedError
      const message = `${error.schemaPath} → ${error.instancePath}: ${error.message}`
      return message
    })
    .join('\n')
}