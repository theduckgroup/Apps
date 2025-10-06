import sleep from "./sleep"

interface Options {
  minMs: number
}

/// Waits for a promise or at least the given milliseconds.
export default async function wait<T>(promise: Promise<T>, options: Options): Promise<T> {
  const startTime = Date.now()

  async function sleepIfNeeded() {
    const elapsedTime = Date.now() - startTime
    const remainingTime = options.minMs - elapsedTime
    await sleep(remainingTime)
  }

  try {
    const result = await promise
    sleepIfNeeded()
    return result

  } catch(error) {
    sleepIfNeeded()
    throw error
  }
}