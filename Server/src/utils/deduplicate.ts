
interface Options<Return> {
  key: unknown
  fn: () => Promise<Return>
}

/**
 * Deduplicates promises.
 * 
 * Try not to use this for functions with side effects.
 */
export default async function deduplicate<Return>(options: Options<Return>): Promise<Return> {
  const { key, fn } = options
  const cacheKey = JSON.stringify(key)

  if (pendingPromises.has(cacheKey)) {
    // console.log(`Reuse existing promise for ${cacheKey}`)
    return pendingPromises.get(cacheKey) as Promise<Return>
  }

  // console.log(`Creating new promise for ${cacheKey}`);
  const promise = fn()

  pendingPromises.set(cacheKey, promise)

  try {
    return await promise

  } finally {
    pendingPromises.delete(cacheKey)
  }
}

const pendingPromises = new Map<string, Promise<unknown>>()