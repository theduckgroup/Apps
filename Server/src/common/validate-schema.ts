import { DefinedError } from 'ajv'
import Ajv, { Schema, JTDDataType } from 'ajv/dist/jtd'
import createHttpError from 'http-errors'

const ajv = new Ajv({ allErrors: true })

/**
 * Validates data with given schema. This is a TypeScript assertion function.
 * 
 * Usage:
 * ```
 * const schema = {
 *    properties: {
 *      foo: { type: 'string' }
 *    }
 * } as const
 *
 * try {
 *   validateSchema<typeof schema>(data, 'schema-id', schema)
 *   // Can use data.foo here
 * } catch {
 *    
 * }
 * ```
 */
export default function validateSchema<T>(data: unknown, schemaId: string, schema: Schema): asserts data is JTDDataType<T> {
  let validate = ajv.getSchema<JTDDataType<T>>(schemaId)

  if (!validate) {
    ajv.addSchema(schema, schemaId)
    validate = ajv.getSchema<JTDDataType<T>>(schemaId)!
  }
  
  if (!validate(data)) {
    const message = validate.errors!
      .map(x => {
        // error.instancePath and error.propertyName are always null
        const error = x as DefinedError
        return error.message
      })
      .join('\n')

    throw createHttpError(400, message);
  }
}