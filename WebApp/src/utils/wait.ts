import sleep from "src/utils/sleep"

interface Options {
  minMs: number
}

/// Waits for a promise or at least the given milliseconds.
export default async function wait<T>(promise: Promise<T>, options: Options): Promise<T>{
  const [result, _] = await Promise.all([promise, sleep(options.minMs)])
  return result
}