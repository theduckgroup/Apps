import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router'
import { Anchor, Button, Group, Loader, Stack, Text, Title } from '@mantine/core'
import { useMutation } from '@tanstack/react-query'
import { ObjectId } from 'bson'
import { IconChevronLeft, IconPencil } from '@tabler/icons-react'
import { produce } from 'immer'

import { usePath, useApi } from 'src/app/contexts'
import { WsTemplate } from 'src/ws-app/models/WsTemplate'
import { EditMetadataModal } from './EditMetadataModal'
import ContentEditor from './ContentEditor'
import useRepeatedModal from 'src/utils/use-repeated-modal'
import formatError from 'src/common/format-error'
import { Dispatch, ReduceState } from 'src/utils/types-lib'

export default function TemplateEditorPage() {
  const { quizId } = useParams()
  const { axios } = useApi()
  const { navigate } = usePath()
  const [template, setTemplate] = useState<WsTemplate | null>(null)
  const [dirty, setDirty] = useState(false)

  const { mutate: loadTemplate, error: loadError, isPending: isLoading } = useMutation({
    mutationFn: async () => {
      if (quizId) {
        return (await axios.get(`/ws-app/${quizId}`)).data as WsTemplate

      } else {
        const template: WsTemplate = {
          id: new ObjectId().toString(),
          name: 'New Template',
          code: 'TEMPLATE',
          emailRecipients: [],
          suppliers: [],
          sections: [
            {
              id: new ObjectId().toString(),
              name: 'Section 1',
              rows: []
            }
          ]
        }

        return template
      }
    },
    onSuccess: (data) => {
      setTemplate(data)
    }
  })

  useEffect(() => {
    loadTemplate()
  }, [loadTemplate])

  const { mutate: saveQuiz, error: saveError, isPending: isSaving } = useMutation({
    mutationFn: async (template: WsTemplate) => {
      await axios.put(`/template/${template.id}`, template)
    }
  })

  useEffect(() => {
    if (dirty) {
      saveQuiz(template!)
      setDirty(false)
    }

  }, [dirty, setDirty, template, saveQuiz])

  const setQuizAndSave: React.Dispatch<React.SetStateAction<WsTemplate | null>> = useCallback((reduceQuiz) => {
    setTemplate(reduceQuiz)
    setDirty(true)
  }, [setTemplate, setDirty])

  return (
    <Stack>
      {/* <title>{quiz ? quiz.name : 'FOH Test'} | The Duck Group</title> */}
      <title>'WS Template | The Duck Group</title>

      {/* Save error */}
      {
        saveError &&
        <Stack align='center'>
          <Group>
            <Text c='red'>{formatError(saveError)}</Text>
            {/* <Button variant='subtle' size='compact-md'>Retry</Button> */}
            <Anchor href='#' onClick={() => saveQuiz(template!)}>Retry</Anchor>
          </Group>
        </Stack>
      }

      {/* Home link */}
      <Anchor size='sm' href='#' onClick={() => navigate(`/list`)}>
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

        if (!template) {
          return <>???</>
        }

        return (
          <>
            <title>{template!.name + ' | The Duck Group'}</title>
            <Content template={template} setTemplate={setQuizAndSave} isSaving={isSaving} />
          </>
        )
      })()}
    </Stack>
  )
}

function Content({ template, setTemplate, isSaving }: {
  template: WsTemplate,
  setTemplate: React.Dispatch<React.SetStateAction<WsTemplate | null>>,
  isSaving: boolean
}) {
  const editModal = useRepeatedModal()
  const [editModalOptions, setEditModalOptions] = useState<EditMetadataModal.Options | undefined>()

  function handleEdit() {
    setEditModalOptions({
      data: {
        name: template.name,
        code: template.code,
        emailRecipients: template.emailRecipients,
      },
      onSave: data => {
        const modifiedTemplate = produce(template!, template => {
          template.name = data.name
          template.code = data.code
          template.emailRecipients = data.emailRecipients
        })

        setTemplate(modifiedTemplate)
      }
    })

    editModal.open()
  }

  const setData: Dispatch<ReduceState<[WsTemplate.Supplier[], WsTemplate.Section[]]>> = (fn) => {
    setTemplate(template => {
      const [suppliers, sections] = fn([template!.suppliers, template!.sections])

      return { ...template!, suppliers, sections }
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
            <Title order={3} c='gray.1'>{template!.name}</Title>
            <Button variant='light' size='compact-xs' onClick={handleEdit}>
              <Group gap='0.25rem'>
                <IconPencil size={14} />
                Edit
              </Group>
            </Button>
          </Group>
          {/* Code, items per page */}
          <Stack gap='0'>
            <Text>Code: {template.code}</Text>
            <Text>Email Recipients: {template.emailRecipients.join(', ')}</Text>
          </Stack>
        </Stack>
        {/* Save loader */}
        {isSaving && <Loader size='sm' />}
      </Group>

      {/* Items editor */}
      <ContentEditor
        suppliers={template.suppliers}
        sections={template.sections}
        // onChange={(items, sections) => {
        //   setQuiz(quiz => ({ ...quiz!, items, sections }))
        //   saveQuiz()
        // }}
        setData={setData}
      />

      {/* Modals */}
      {editModal.modalIDs.map(id =>
        <EditMetadataModal key={id} opened={editModal.isOpened(id)} close={editModal.close} options={editModalOptions} />
      )}

    </Stack>
  )
}