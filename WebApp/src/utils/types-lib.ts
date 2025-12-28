// React reference:
// type Dispatch<A> = (value: A) => void;
// type SetStateAction<S> = S | ((prevState: S) => S);
// type Reducer<S, A> = (prevState: S, action: A) => S;
// type ReducerWithoutAction<S> = (prevState: S) => S;

export type Dispatch<A> = (action: A) => void
export type Reducer<T> = (prev: T) => T
export type ValueOrReducer<T> = T | Reducer<T>