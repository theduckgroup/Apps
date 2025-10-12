import { Container, MantineProvider, Stack, Text } from '@mantine/core'

import theme from './mantine-theme'
import { useParams } from 'react-router'

export default function QuizResponsePage() {
  const { id } = useParams()

  if (!id) {
    return <Text>Not Found</Text>
  }
  
  return (
    <MantineProvider defaultColorScheme='light' theme={theme}>
      <Container>
        <Stack>
          <Text>Hello {id}</Text>
        </Stack>
      </Container>
    </MantineProvider>
  )
}