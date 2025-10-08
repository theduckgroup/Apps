import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router'
import { Anchor, Button, Group, Loader, Stack, Text, Title } from '@mantine/core'
import axios from 'axios'
import { useMutation } from '@tanstack/react-query'
import { ObjectId } from 'bson'
import { IconChevronLeft, IconPencil } from '@tabler/icons-react'

import { Quiz } from 'src/models/Quiz'
import { EditQuizMetadataModal } from './EditQuizMetadataModal'
import QuizItemsEditor from './QuizItemsEditor'
import useRepeatedModal from 'src/common/use-repeated-modal'
import { produce } from 'immer'
import formatError from 'src/common/format-error'

export default function QuizPage() {
  const navigate = useNavigate()
  const { quizId } = useParams()
  const [quiz, setQuiz] = useState<Quiz | null>(null)

  const { mutate: loadQuiz, error: loadError, isPending: isLoading } = useMutation({
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

  const { mutate: saveQuiz, error: saveError, isPending: isSaving } = useMutation({
    mutationFn: async () => {
      await axios.put(`/api/quiz/${quiz!.id}`, quiz)
    }
  })

  const editModal = useRepeatedModal()
  const [editModalOptions, setEditModalOptions] = useState<EditQuizMetadataModal.Options | undefined>()

  function handleEdit() {
    setEditModalOptions({
      data: {
        name: quiz!.name,
        code: quiz!.code,
        itemsPerPage: quiz!.itemsPerPage
      },
      onSave: data => {
        const modifiedQuiz = produce(quiz!, quiz => {
          quiz.name = data.name
          quiz.code = data.code
          quiz.itemsPerPage = data.itemsPerPage
        })

        setQuiz(modifiedQuiz)
        saveQuiz()
      }
    })

    editModal.open()
  }

  return (
    <Stack>
      {/* Save error */}
      {
        saveError &&
        <Stack align='center'>
          <Group>
            <Text c='red'>{formatError(saveError)}</Text>
            {/* <Button variant='subtle' size='compact-md'>Retry</Button> */}
            <Anchor href='#' onClick={() => saveQuiz()}>Retry</Anchor>
          </Group>
        </Stack>
      }

      {/* Home link */}
      <Anchor size='sm' href='#' onClick={() => navigate('/quiz-list')}>
        <Group gap='0.2rem'>
          <IconChevronLeft size={18} />
          Home
        </Group>
      </Anchor>

      {/* Title + Save Loader */}
      <Group>
        <Title order={3} mr='auto'>Quiz</Title>
        {isSaving && <Loader size='sm' />}
      </Group>

      {/* Main content */}
      {(() => {
        if (isLoading) {
          return <Text>Loading...</Text>
        }

        if (loadError) {
          return <Text c='red'>{loadError.message}</Text>
        }

        if (!quiz) {
          return <>???</>
        }

        return (
          <Stack gap='lg'>
            <Stack gap='xs' align='flex-start'>
              {/* Quiz title + metadata */}
              <Title order={4}>{quiz!.name}</Title>
              <Stack gap='0'>
                <Text>Code: {quiz.code}</Text>
                <Text>Items per Page: {quiz.itemsPerPage}</Text>
              </Stack>

              {/* Modify button */}
              {/* <Anchor href='#' onClick={e => { e.preventDefault(); handleEdit(); }}>
                <Group gap='0.25rem' wrap='nowrap'>
                  <IconPencil size={14} />
                  <Text fz='sm'>Edit</Text>
                </Group>
              </Anchor> */}
              <Button variant='light' size='compact-xs' onClick={handleEdit}>
                <Group gap='0.25rem'>
                  <IconPencil size={14} />
                  Edit
                </Group>

              </Button>
            </Stack>

            {/* Items editor */}
            <QuizItemsEditor
              items={quiz.items}
              sections={quiz.sections}
              onChange={(items, sections) => {
                setQuiz(quiz => ({ ...quiz!, items, sections }))
                saveQuiz()
              }}
            />
          </Stack>
        )
      })()}

      {/* Modals */}
      {editModal.modalIDs.map(id =>
        <EditQuizMetadataModal key={id} opened={editModal.isOpened(id)} close={editModal.close} options={editModalOptions} />
      )}
    </Stack>
  )
}