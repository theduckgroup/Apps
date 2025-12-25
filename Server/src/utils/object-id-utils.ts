import { ObjectId } from 'mongodb'

/**
 * Extracts keys of T where the value has type V..
 */
type KeysOfValue<T, V> = {
  [K in keyof T]: T[K] extends V ? K : never
}[keyof T]

/** 
 * Replaces the type of property K in T with type V .
 */
type ReplacePropertyType<T, K extends keyof T, V> = Omit<T, K> & { [P in K]: V }

/**
 * Converts a specific property of an object or an array of objects to ObjectId.
 */
export function stringPropertyToObjectId<T, K extends KeysOfValue<T, string>>(data: T, key: K): ReplacePropertyType<T, K, ObjectId>
export function stringPropertyToObjectId<T, K extends KeysOfValue<T, string>>(data: T[], key: K): ReplacePropertyType<T, K, ObjectId>[]

export function stringPropertyToObjectId<T, K extends KeysOfValue<T, string>>(data: T | T[], key: K): ReplacePropertyType<T, K, ObjectId> | ReplacePropertyType<T, K, ObjectId>[] {
  const transform = (item: T): ReplacePropertyType<T, K, ObjectId> => ({
    ...item,
    [key]: new ObjectId(item[key] as unknown as string)
  })

  if (Array.isArray(data)) {
    return data.map(transform)
  }

  return transform(data)
}

/**
 * Converts an ObjectId property of an object or an array to a string.
 */
export function objectIdPropertyToString<T, K extends KeysOfValue<T, ObjectId>>(data: T, key: K): ReplacePropertyType<T, K, string>
export function objectIdPropertyToString<T, K extends KeysOfValue<T, ObjectId>>(data: T[], key: K): ReplacePropertyType<T, K, string>[]

export function objectIdPropertyToString<T, K extends KeysOfValue<T, ObjectId>>(data: T | T[], key: K): ReplacePropertyType<T, K, string> | ReplacePropertyType<T, K, string>[] {
  const transform = (item: T): ReplacePropertyType<T, K, string> => ({
    ...item,
    [key]: (item[key] as unknown as ObjectId).toString()
  })

  if (Array.isArray(data)) {
    return data.map(transform)
  }

  return transform(data)
}