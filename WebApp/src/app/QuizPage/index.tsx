import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router'
import { Anchor, Group, Loader, Stack, Text, Title } from '@mantine/core'
import axios from 'axios'
import { useMutation, useQuery } from '@tanstack/react-query'
import { ObjectId } from 'bson'

import { Quiz } from 'src/models/Quiz'
import QuizItemsEditor from './QuizItemsEditor'
import { IconChevronLeft } from '@tabler/icons-react'

export default function QuizPage() {
  const navigate = useNavigate()
  const { quizId } = useParams()
  const [quiz, setQuiz] = useState<Quiz | null>(null)

  const { mutate: loadQuiz, error, isPending } = useMutation({
    mutationFn: async () => {
      if (quizId) {
        return (await axios.get(`/api/quiz/${quizId}`)).data as Quiz

      } else {
        const quiz: Quiz = {
          id: (new ObjectId()).toString(),
          name: 'New Quiz',
          code: '',
          itemsPerPage: 10,
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
    onSuccess: (data) => {
      setQuiz(data)
    }
  })

  useEffect(() => {
    loadQuiz()
  }, [loadQuiz])

  const { mutate: save, error: saveError, isPending: isSaving } = useMutation({
    mutationFn: async () => {
      await axios.put(`/api/quiz/${quiz!.id}`, quiz)
    }
  })

  return (
    <Stack>
      {
        saveError &&
        // <Paper bg='red' c='white' radius='xs' px='md' py='0.5rem'>
        <Stack align='center'>
          <Group>
            <Text c='red'>{saveError.message}</Text>
            {/* <Button variant='subtle' size='compact-md'>Retry</Button> */}
            <Anchor href='#' onClick={() => save()}>Retry</Anchor>
          </Group>
        </Stack>
        // </Paper>
      }
      <Anchor size='sm' href='#' onClick={() => navigate('/quiz-list')}>
        <Group gap='0.2rem'>
          <IconChevronLeft size={18} />
          Home
        </Group>
      </Anchor>
      <Group>
        <Title order={3} mr='auto'>Quiz</Title>
        {isSaving && <Loader size='sm' />}
      </Group>

      {(() => {
        if (isPending) {
          return <Text>Loading...</Text>
        }

        if (error) {
          return <Text c='red'>{error.message}</Text>
        }

        if (!quiz) {
          return <>???</>
        }

        return (
          <>
            {/* Quiz title etc */}
            <Title order={4}>{quiz!.name}</Title>

            {/* Items editor */}
            <QuizItemsEditor
              items={quiz.items}
              sections={quiz.sections}
              onChange={(items, sections) => {
                setQuiz(quiz => ({ ...quiz!, items, sections }))
                save()
              }}
            />
          </>
        )

      })()}
    </Stack>
  )
}