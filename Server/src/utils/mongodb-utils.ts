import { ObjectId } from 'bson'

/**
 * Transforms `_id: ObjectId` to `id: string`.
 */
export function jsonifyMongoId<T extends { _id?: ObjectId }>(object: T) {
  const { _id, ...rest } = object
  const obj = { ...rest, id: _id?.toString() }
  return obj
}