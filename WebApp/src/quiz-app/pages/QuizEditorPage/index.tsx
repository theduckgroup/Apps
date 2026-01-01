import { useEffect, useMemo, useRef, useState } from 'react'
import { useBlocker, useParams } from 'react-router'
import { Anchor, Button, Group, Stack, Text, Title } from '@mantine/core'
import { useMutation } from '@tanstack/react-query'
import { ObjectId } from 'bson'
import { IconChevronLeft, IconPencil } from '@tabler/icons-react'
import { produce } from 'immer'

import { usePath, useApi } from 'src/app/contexts'
import { Quiz } from 'src/quiz-app/models/Quiz'
import { EditMetadataModal } from './EditMetadataModal'
import ContentEditor from './ContentEditor'
import useModal from 'src/utils/use-modal'
import formatError from 'src/common/format-error'
import { Dispatch, Reducer } from 'src/utils/types-lib'
import { EditorFooter } from 'src/utils/EditorFooter'
import { UnsavedChangesModal } from 'src/utils/UnsavedChangesModal'

export default function QuizEditorPage() {
  const { quizId } = useParams()
  const { axios } = useApi()
  const { navigate } = usePath()

  const [quiz, setQuiz] = useState<Quiz | null>(null)
  const [didChange, setDidChange] = useState(false) // Whether user made changes or not
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false) // Whether there is pending changes
  const blocker = useBlocker(hasUnsavedChanges)
  const mainRef = useRef<HTMLDivElement>(null)

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

  // Save

  const { mutate: saveQuiz, mutateAsync: saveQuizAsync, error: saveError, isPending: saving } = useMutation({
    mutationFn: async (quiz: Quiz) => {
      await axios.put(`/quiz/${quiz.id}`, quiz)
    },
    onSuccess: () => {
      setHasUnsavedChanges(false)
    }
  })

  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (hasUnsavedChanges) {
        e.preventDefault()
      }
    }

    window.addEventListener('beforeunload', handleBeforeUnload)

    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload)
    }
  }, [hasUnsavedChanges])

  return (
    <>
      <div ref={mainRef} className='flex flex-col gap-6 items-start'>
        {/* Back link */}
        <Anchor size='sm' onClick={e => { e.preventDefault(); navigate(`/list`) }}>
          <Group gap='0.2rem'>
            <IconChevronLeft size={18} />
            Back to Tests
          </Group>
        </Anchor>

        {/* Content */}
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
                setQuiz={valueOrReducer => {
                  setQuiz(valueOrReducer)
                  setDidChange(true)
                  setHasUnsavedChanges(true)
                }}
              />
            </>
          )
        })()}
      </div>

      {didChange &&
        <EditorFooter
          editorRef={mainRef}
          hasUnsavedChanges={hasUnsavedChanges}
          save={() => saveQuizAsync(quiz!)}
        />
      }

      <UnsavedChangesModal
        blocker={blocker}
        save={() => saveQuizAsync(quiz!)}
      />
    </>
  )
}

function Content({ quiz, setQuiz }: {
  quiz: Quiz,
  setQuiz: React.Dispatch<React.SetStateAction<Quiz | null>>
}) {
  const editModal = useModal(EditMetadataModal)

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
    <Stack className='w-full' gap='md'>
      {/* Title + Edit button */}
      <Group w='100%' gap='md' align='baseline'>
        <Title order={2} c='gray.1'>{quiz.name}</Title>
        <Button variant='light' size='compact-xs' fw='normal' onClick={handleEdit}>
          <Group gap='0.25rem'>
            <IconPencil size={13} />
            Edit
          </Group>
        </Button>
      </Group>

      {/* Code, email recipients */}
      <Stack gap='0'>
        <Text>Code: {quiz.code}</Text>
        <Text>Email Recipients: {quiz.emailRecipients.join(', ')}</Text>
      </Stack>

      {/* Content editor */}
      <ContentEditor
        items={quiz.items}
        sections={quiz.sections}
        setData={setData}
      />

      {/* Modals */}
      {editModal.element}
    </Stack>
  )
}