import { ErrorBoundary } from 'react-error-boundary'
import { Code, Stack, Text } from '@mantine/core'
import formatError from 'src/common/format-error'

export function withErrorBoundary(children: React.ReactNode) {
  function FallbackComponent({ error, resetErrorBoundary }: {
    error: Error,
    resetErrorBoundary: () => void
  }) {
    return (
      <Stack role='alert'>
        <Text c='red.5' fz='md'>Something went wrong...</Text>
        <Code block>{formatError(error)}</Code>
        {/* <button onClick={resetErrorBoundary}>Try again</button> */}
      </Stack>
    )
  }

  return (
    <ErrorBoundary FallbackComponent={FallbackComponent} onReset={() => { }}>
      {children}
    </ErrorBoundary>
  )
}
