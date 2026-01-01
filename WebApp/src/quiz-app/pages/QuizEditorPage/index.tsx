import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router'
import { Anchor, Button, Group, Loader, Stack, Text, Title } from '@mantine/core'
import { useMutation } from '@tanstack/react-query'
import { ObjectId } from 'bson'
import { IconArrowBackUp, IconChevronLeft, IconPencil } from '@tabler/icons-react'
import { produce } from 'immer'

import { usePath, useApi } from 'src/app/contexts'
import { Quiz } from 'src/quiz-app/models/Quiz'
import { EditMetadataModal } from './EditMetadataModal'
import ContentEditor from './ContentEditor'
import useModal from 'src/utils/use-modal'
import formatError from 'src/common/format-error'
import { Dispatch, Reducer } from 'src/utils/types-lib'
import { ConfirmModal } from 'src/utils/ConfirmModal'

export default function QuizEditorPage() {
  const { quizId } = useParams()
  const { axios } = useApi()
  const { navigate } = usePath()
  const [initialQuiz, setInitialQuiz] = useState<Quiz | null>(null)
  const [quiz, setQuiz] = useState<Quiz | null>(null)
  const [saveTrigger, setSaveTrigger] = useState(0)
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
      setInitialQuiz(data)
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

  const setNeedsSave = useCallback(() => {
    setSaveTrigger(x => x + 1)
  }, [setSaveTrigger])

  useEffect(() => {
    if (saveTrigger > 0) {
      saveQuiz(quiz!)
    }
  }, [quiz, saveQuiz, saveTrigger])

  const setQuizAndSave: React.Dispatch<React.SetStateAction<Quiz | null>> = useCallback((reduceQuiz) => {
    setQuiz(reduceQuiz)
    setNeedsSave()
    setDirty(true)
  }, [setQuiz, setNeedsSave])

  const revertQuizAndSave = useCallback(() => {
    setQuiz(initialQuiz)
    setNeedsSave()
    setDirty(false)
  }, [initialQuiz, setQuiz, setNeedsSave])

  return (
    <Stack>
      {/* <title>{quiz ? quiz.name : 'FOH Test'} | The Duck Group</title> */}
      <title>'FOH Test | The Duck Group</title>

      {/* Save error */}
      {
        saveError &&
        <Stack align='center'>
          <Group>
            <Text c='red'>{formatError(saveError)}</Text>
            {/* <Button variant='subtle' size='compact-md'>Retry</Button> */}
            <Anchor onClick={e => { e.preventDefault(); saveQuiz(quiz!) }}>Retry</Anchor>
          </Group>
        </Stack>
      }

      {/* Home link */}
      <Anchor size='sm' onClick={e => { e.preventDefault(); navigate(`/list`) }}>
        <Group gap='0.2rem'>
          <IconChevronLeft size={18} />
          Back to Tests
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

        return (
          <>
            <title>{quiz.name + ' | The Duck Group'}</title>
            <Content
              quiz={quiz}
              setQuiz={setQuizAndSave}
              revertQuiz={revertQuizAndSave}
              saving={isSaving}
              dirty={dirty}
            />
          </>
        )
      })()}
    </Stack>
  )
}

function Content({ quiz, setQuiz, revertQuiz, saving, dirty }: {
  quiz: Quiz,
  setQuiz: React.Dispatch<React.SetStateAction<Quiz | null>>,
  revertQuiz: () => void,
  saving: boolean
  dirty: boolean
}) {
  const editModal = useModal(EditMetadataModal)
  const confirmModal = useModal(ConfirmModal)

  function handleEdit() {
    editModal.open({
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
  }

  function handleRevert() {
    confirmModal.open({
      title: 'Revert Changes?',
      message: 'The test will be reverted back to the state when you visited this page (before any changes were made).',
      actions: [
        {
          label: 'Revert',
          role: 'destructive',
          handler: revertQuiz
        }
      ]
    })
  }
  const setData: Dispatch<Reducer<[Quiz.Item[], Quiz.Section[]]>> = (fn) => {
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
        <Stack w='100%' gap='xs' align='flex-start' mr='auto'>
          {/* Quiz title + Edit button + Save loader + Revert button */}
          <Group w='100%' gap='md' align='baseline'>
            {/* Name */}
            <Title order={2} c='gray.1'>{quiz!.name}</Title>
            {/* Edit */}
            <Button variant='light' size='compact-sm' fw='normal' onClick={handleEdit}>
              <Group gap='0.35rem'>
                <IconPencil size={13} />
                Edit
              </Group>
            </Button>
            {/* Save loader */}
            {saving && <Loader ml='auto' size='xs' />}
            {/* Revert button */}
            {(dirty && !saving) &&
              <Button ml='auto' variant='light' size='compact-sm' fw='normal' onClick={handleRevert}>
                <Group gap='0.35rem'>
                  <IconArrowBackUp size={15} />
                  Revert
                </Group>
              </Button>
            }
          </Group>
          {/* Code, items per page */}
          <Stack gap='0'>
            <Text>Code: {quiz.code}</Text>
            <Text>Email Recipients: {quiz.emailRecipients.join(', ')}</Text>
          </Stack>
        </Stack>
      </Group>

      {/* Content editor */}
      <ContentEditor
        items={quiz.items}
        sections={quiz.sections}
        setData={setData}
      />

      {/* Modals */}
      {editModal.element}
      {confirmModal.element}
    </Stack>
  )
}