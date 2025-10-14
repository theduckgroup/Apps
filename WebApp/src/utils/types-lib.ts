
export type ReduceState<S> = (prevState: S) => S

export type Dispatch<A> = (action: A) => void