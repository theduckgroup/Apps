import { useEffect, useState } from 'react'
import { useParams } from 'react-router'
import { Stack, Text, Title } from '@mantine/core'
import axios from 'axios'
import { useQuery } from '@tanstack/react-query'
import { ObjectId } from 'bson'

import { Quiz } from 'src/models/Quiz'
import QuizItemsEditor from './QuizItemsEditor'

export default function QuizPage() {
  const { quizId } = useParams()
  const [quiz, setQuiz] = useState<Quiz | null>(null)

  const { data, error, isLoading } = useQuery({
    queryKey: ['quiz', quizId],
    queryFn: async (args) => {
      console.info(`Querying quizId = ${quizId}`)

      if (quizId) {
        return (await axios.get(`/api/quiz/${quizId}`)).data as Quiz

      } else {
        const quiz: Quiz = {
          id: (new ObjectId()).toString(),
          name: 'New Quiz',
          items: [],
          sections: [
            {
              id: new ObjectId().toString(),
              name: 'Section 1',
              rows: []
            }
          ]
        }

        return quiz
      }
    },
    staleTime: Infinity,
    refetchOnWindowFocus: true
  })

  useEffect(() => {
    if (data) {
      setQuiz(data)
    }
  }, [data])

  if (isLoading) {
    return <Text>Loading...</Text>
  }

  if (error) {
    return <Text c='red'>{error.message}</Text>
  }

  if (!quiz) {
    return <>???</>
  }

  return (
    <Stack>
      <Title order={3}>Quiz</Title>
      <Title order={4}>{quiz!.name}</Title>
      <QuizItemsEditor
        items={quiz.items}
        sections={quiz.sections}
        onChange={(items, sections) => setQuiz(quiz => ({ ...quiz!, items, sections }))}
      />
    </Stack>
  )
}