import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router'
import { Anchor, Button, Group, Loader, Stack, Text, Title } from '@mantine/core'
import { useMutation } from '@tanstack/react-query'
import { ObjectId } from 'bson'
import { IconChevronLeft, IconPencil } from '@tabler/icons-react'
import { produce } from 'immer'

import { usePath, useApi } from 'src/app/contexts'
import { Quiz } from 'src/quiz-app/models/Quiz'
import { EditQuizMetadataModal } from './EditQuizMetadataModal'
import QuizItemsEditor from './QuizItemsEditor'
import useRepeatedModal from 'src/utils/use-repeated-modal'
import formatError from 'src/common/format-error'
import { Dispatch, ReduceState } from 'src/utils/types-lib'

export default function QuizPage() {
  const { quizId } = useParams()
  const { axios } = useApi()
  const { navigate } = usePath()
  const [quiz, setQuiz] = useState<Quiz | null>(null)
  const [dirty, setDirty] = useState(false)
  
  const { mutate: loadQuiz, error: loadError, isPending: isLoading } = useMutation({
    mutationFn: async () => {
      if (quizId) {
        return (await axios.get(`/quiz/${quizId}`)).data as Quiz

      } else {
        const quiz: Quiz = {
          id: new ObjectId().toString(),
          name: 'New Test',
          code: 'NEW_TEST',
          emailRecipients: [],
          items: [],
          sections: [
            {
              id: new ObjectId().toString(),
              name: 'Section 0',
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
    mutationFn: async (quiz: Quiz) => {
      await axios.put(`/quiz/${quiz.id}`, quiz)
    }
  })

  useEffect(() => {
    if (dirty) {
      saveQuiz(quiz!)
      setDirty(false)
    }

  }, [dirty, setDirty, quiz, saveQuiz])

  const setQuizAndSave: React.Dispatch<React.SetStateAction<Quiz | null>> = useCallback((reduceQuiz) => {
    setQuiz(reduceQuiz)
    setDirty(true)
  }, [setQuiz, setDirty])

  return (
    <Stack>
      {/* Save error */}
      {
        saveError &&
        <Stack align='center'>
          <Group>
            <Text c='red'>{formatError(saveError)}</Text>
            {/* <Button variant='subtle' size='compact-md'>Retry</Button> */}
            <Anchor href='#' onClick={() => saveQuiz(quiz!)}>Retry</Anchor>
          </Group>
        </Stack>
      }

      {/* Home link */}
      <Anchor size='sm' href='#' onClick={() => navigate(`/list`)}>
        <Group gap='0.2rem'>
          <IconChevronLeft size={18} />
          Home
        </Group>
      </Anchor>

      {/* Main content */}
      {(() => {
        if (isLoading) {
          return <Text>Loading...</Text>
        }

        if (loadError) {
          return <Text c='red'>{formatError(loadError)}</Text>
        }

        if (!quiz) {
          return <>???</>
        }

        return <Content quiz={quiz} setQuiz={setQuizAndSave} isSaving={isSaving} />
      })()}
    </Stack>
  )
}

function Content({ quiz, setQuiz, isSaving }: {
  quiz: Quiz,
  setQuiz: React.Dispatch<React.SetStateAction<Quiz | null>>,
  isSaving: boolean
}) {
  const editModal = useRepeatedModal()
  const [editModalOptions, setEditModalOptions] = useState<EditQuizMetadataModal.Options | undefined>()

  function handleEdit() {
    setEditModalOptions({
      data: {
        name: quiz.name,
        code: quiz.code,
        emailRecipients: quiz.emailRecipients,
      },
      onSave: data => {
        const modifiedQuiz = produce(quiz!, quiz => {
          quiz.name = data.name
          quiz.code = data.code
          quiz.emailRecipients = data.emailRecipients
        })

        setQuiz(modifiedQuiz)
      }
    })

    editModal.open()
  }

  const setData: Dispatch<ReduceState<[Quiz.Item[], Quiz.Section[]]>> = (fn) => {
    setQuiz(quiz => {
      const [items, sections] = fn([quiz!.items, quiz!.sections])

      return {
        ...quiz!,
        items: items,
        sections: sections
      }
    })
  }

  return (
    <Stack gap='lg'>
      {/* Quiz metadata + Save loader */}
      <Group align='flex-start'>
        {/* Quiz metadata + Edit button */}
        <Stack gap='xs' align='flex-start' mr='auto'>
          {/* Quiz title + Edit button */}
          <Group gap='md' align='baseline'>
            <Title order={3}>{quiz!.name}</Title>
            <Button variant='light' size='compact-xs' onClick={handleEdit}>
              <Group gap='0.25rem'>
                <IconPencil size={14} />
                Edit
              </Group>
            </Button>
          </Group>
          {/* Code, items per page */}
          <Stack gap='0'>
            <Text>Code: {quiz.code}</Text>
            <Text>Email Recipients: {quiz.emailRecipients.join(', ')}</Text>
          </Stack>
        </Stack>
        {/* Save loader */}
        {isSaving && <Loader size='sm' />}
      </Group>

      {/* Items editor */}
      <QuizItemsEditor
        items={quiz.items}
        sections={quiz.sections}
        // onChange={(items, sections) => {
        //   setQuiz(quiz => ({ ...quiz!, items, sections }))
        //   saveQuiz()
        // }}
        setData={setData}
      />

      {/* Modals */}
      {editModal.modalIDs.map(id =>
        <EditQuizMetadataModal key={id} opened={editModal.isOpened(id)} close={editModal.close} options={editModalOptions} />
      )}

    </Stack>
  )
}