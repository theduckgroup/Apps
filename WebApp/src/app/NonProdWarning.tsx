import { Box, Text } from '@mantine/core'
import { useEnv } from './contexts'

export function NonProdWarning() {
  const { info } = useEnv()

  if (!info || info.env === 'production') {
    return null
  }

  return (
    <Box className='bg-yellow-300 text-neutral-900 text-center px-2 py-1.5 rounded-sm w-full'>
      <Text>You are in test environment. Data is not shared with production.</Text>
    </Box>
  )
}
