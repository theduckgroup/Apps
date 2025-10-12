import { useEffect } from 'react'
import { Button, Grid, Group, Paper, Stack, Text, Title } from '@mantine/core'
import { IconPlus } from '@tabler/icons-react'
import { useQuery } from '@tanstack/react-query'

import { usePath, useApi } from 'src/app/contexts'
import { QuizMetadata } from 'src/quiz-app/models/Quiz'
import quizEventHub from 'src/quiz-app/event-hub'
import formatError from 'src/common/format-error'

const QuizListPage = () => {
  const { axios } = useApi()

  const { data, error, isLoading, refetch } = useQuery({
    queryKey: ['quizzes'],
    queryFn: async () => {
      const metaquizzes = (await axios.get('/quizzes')).data as QuizMetadata[]
      return metaquizzes
    }
  })

  useEffect(() => {
    const unsub = quizEventHub.onQuizzesChanged(() => {
      refetch()
    })

    return unsub
  }, [refetch])

  return (
    <Stack gap='md' align='flex-start'>
      <Title order={2}>Tests</Title>
      {(() => {
        if (isLoading) {
          return <Text>Loading...</Text>
        }

        if (error) {
          return <Text c='red'>{formatError(error)}</Text>
        }
        if (!data) {
          return <Text>???</Text>
        }

        return <Content data={data} />
      })()}
    </Stack>
  )
}

function Content({ data }: {
  data: QuizMetadata[]
}) {
  const { navigate } = usePath()

  return (
    <Stack align='flex-start' w='100%'>
      <Grid w='100%'>
        {
          data.map(metaquiz => <QuizComponent key={metaquiz.id} metaquiz={metaquiz} />)
        }
      </Grid>
      {
        import.meta.env.DEV &&
        <Button
          variant='filled'
          leftSection={<IconPlus size={16} strokeWidth={2} />}
          onClick={() => navigate('/quiz')}
        >
          [dev] Add Test
        </Button>
      }
    </Stack>
  )
}

function QuizComponent({ metaquiz }: {
  metaquiz: QuizMetadata
}) {
  const { navigate } = usePath()

  return (
    <Grid.Col span={{ base: 12, sm: 4 }}>
      <Paper px='md' py='sm' bg='dark.8' withBorder>
        <Stack align='flex-start' gap='md'>
          <Stack gap='0.25rem'>
            <Title order={5}>{metaquiz.name}</Title>
            <Stack gap='0'>
              {metaquiz.code && <Text fz='sm' fw={500} opacity={0.5}> {metaquiz.code}</Text>}
              <Text fz='sm'>{metaquiz.itemCount} items</Text>
            </Stack>
          </Stack>
          <Button
            variant='default'
            size='xs'
            // leftSection={<IconPencil size={14}/>}
            // rightSection={<IconArrowNarrowRight size={14}/>}
            onClick={() => navigate(`/quiz/${metaquiz.id}`)}
          >
            <Group gap='0.25rem' align='center'>
              {/* <IconPencil size={14} strokeWidth={1.25} /> */}
              View/Edit
              {/* <IconArrowNarrowRight size={14} /> */}
            </Group>
          </Button>
        </Stack>
      </Paper>
    </Grid.Col>
  )
}

export default QuizListPage