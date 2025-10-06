import { Button, Paper, Stack, Title } from '@mantine/core'
import { useQuery } from '@tanstack/react-query'
import axios from 'axios'
import { useNavigate } from 'react-router'

import { QuizMetadata } from 'src/models/Quiz'

const QuizListPage = () => {
  const navigate = useNavigate()

  const { data, error, isLoading } = useQuery({
    queryKey: ['quizzes'],
    queryFn: async () => {
      const metaquizzes = (await axios.get('/api/quizzes')).data as QuizMetadata[]
      return metaquizzes
    }
  })

  const addQuiz = () => {
    navigate('/quiz')
  }

  if (isLoading) {
    return <p>Loading...</p>
  }

  if (error) {
    return <p>{error.message}</p>
  }

  console.info(`data = ${data}`)

  return (
    <Stack gap='xl' align='flex-start'>
      <Title order={2}>Quizzes</Title>

      {
        data && data.map(metaquiz => {
          return (
            <Paper id={metaquiz.id} p='md'>
              <Title order={3}>{metaquiz.name}</Title>
            </Paper>
          )
        })
      }

      <Button variant='filled' onClick={addQuiz}>Add Quiz</Button>
    </Stack>
  )
}

const QuizElement = () => {
  return (
    <Stack gap='sm'>

    </Stack>
  )
}

export default QuizListPage