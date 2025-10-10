import { Button, Grid, Group, Paper, Stack, Text, Title } from '@mantine/core'
import { IconPlus } from '@tabler/icons-react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router'

import { QuizMetadata } from 'src/quiz/models/Quiz'
import eventHub from 'src/event-hub'
import { useEffect } from 'react'
import { useApi } from 'src/app/providers/ApiContext'
import { usePath } from 'src/app/providers/PathContext'

const QuizListPage = () => {
  const { axios } = useApi()
  const { navigate } = usePath()

  const { data, error, isLoading, refetch } = useQuery({
    queryKey: ['quizzes'],
    queryFn: async () => {
      const metaquizzes = (await axios.get('/quizzes')).data as QuizMetadata[]
      return metaquizzes
    }
  })

  useEffect(() => {
    const unsub = eventHub.onQuizzesChanged(() => {
      refetch()
    })

    return () => {
      unsub()
    }
  }, [refetch])

  if (error) {
    return <p>{error.message}</p>
  }

  return (
    <Stack gap='md' align='flex-start'>
      <Title order={2}>Tests</Title>
      {
        isLoading ? (
          <Text>Loading...</Text>
        ) : (
          data &&
          <Grid w='100%'>
            {
              data.map(metaquiz => <QuizComponent key={metaquiz.id} metaquiz={metaquiz} />)
            }
          </Grid>
        )
      }
      <Button
        variant='filled'
        leftSection={<IconPlus size={16} strokeWidth={2} />}
        onClick={() => navigate('/quiz')}
      >
        Add Test
      </Button>
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