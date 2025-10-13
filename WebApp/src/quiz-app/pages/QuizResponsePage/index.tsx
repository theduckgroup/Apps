import { useParams } from 'react-router'
import { useQuery } from '@tanstack/react-query'
import { Container, MantineProvider, Stack, Text } from '@mantine/core'

import { useApi } from 'src/app/contexts'
import theme from './mantine-theme'
import { QuizResponse, QuizResponsePayload } from 'src/quiz-app/models/QuizResponse'
import formatError from 'src/common/format-error'
import ItemResponseComponent from './ItemResponseComponent'

export default function QuizResponsePage() {
  const { axios } = useApi()
  const { id } = useParams()

  const { data, error, isLoading } = useQuery<QuizResponse>({
    queryKey: ['quiz-response', id],
    queryFn: async () => {
      if (!id) {
        throw new Error('Invalid ID')
      }

      const payload = (await axios.get<QuizResponsePayload>(`/quiz-response/${id}`)).data

      const data: QuizResponse = {
        ...payload,
        createdDate: new Date(payload.createdDate),
        submittedDate: new Date(payload.submittedDate)
      }

      return data
    }
  })

  return (
    <MantineProvider defaultColorScheme='light' theme={theme}>
      <Container p='md'>
        {(() => {
          if (isLoading) {
            return <Text>Loading...</Text>
          }

          if (error) {
            return <Text c='red'>{formatError(error)}</Text>
          }

          return <Content data={data!} />
        })()}
      </Container>
    </MantineProvider>
  )
}

function Content({ data }: { data: QuizResponse }) {
  return (
    <Stack gap='md'>
      {data.quiz.items.map((item, index) => {
        const itemResponse = data.itemResponses.find(x => x.itemId == item.id)

        if (!itemResponse) {
          return <Text c='red'>Item Not Found</Text>
        }

        return <ItemResponseComponent item={item} itemResponse={itemResponse} />
      })}
    </Stack>
  )
}