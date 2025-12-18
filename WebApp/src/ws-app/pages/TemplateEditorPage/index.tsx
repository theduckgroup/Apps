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
import { ContentEditor } from './ContentEditor'
import useModal from 'src/utils/use-modal'
import formatError from 'src/common/format-error'
import { Dispatch, ReduceState } from 'src/utils/types-lib'
import { ConfirmModal } from 'src/utils/ConfirmModal'
import sleep from 'src/common/sleep'

export default function TemplateEditorPage() {
  const { templateId } = useParams()
  const { axios } = useApi()
  const { navigate } = usePath()
  const [initialTemplate, setInitialTemplate] = useState<WsTemplate | null>(null)
  const [template, setTemplate] = useState<WsTemplate | null>(null)
  const [needsSave, setNeedsSave] = useState(false)
  const [dirty, setDirty] = useState(false)

  const { mutate: loadTemplate, error: loadError, isPending: isLoading } = useMutation({
    mutationFn: async () => {
      if (templateId) {
        return (await axios.get(`/templates/${templateId}`)).data as WsTemplate

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
      setInitialTemplate(data)
      setTemplate(data)
    }
  })

  useEffect(() => {
    loadTemplate()
  }, [loadTemplate])

  const { mutate: saveTemplate, error: saveError, isPending: isSaving } = useMutation({
    mutationFn: async (template: WsTemplate) => {
      await axios.put(`/templates/${template.id}`, template)
    }
  })

  useEffect(() => {
    if (needsSave) {
      saveTemplate(template!)
      setNeedsSave(false)
    }
  }, [needsSave, setNeedsSave, template, saveTemplate])

  const setTemplateAndSave: React.Dispatch<React.SetStateAction<WsTemplate | null>> = useCallback(reduce => {
    setTemplate(reduce)
    setNeedsSave(true)
    setDirty(true)
  }, [setTemplate, setNeedsSave])

  const resetTemplateAndSave = useCallback(() => {
    setTemplate(initialTemplate)
    setNeedsSave(true)
    setDirty(false)
  }, [initialTemplate, setTemplate])

  return (
    <Stack>
      {/* <title>{quiz ? quiz.name : 'FOH Test'} | The Duck Group</title> */}
      <title>Weekly Spending | The Duck Group</title>

      {/* Save error */}
      {
        saveError &&
        <Stack align='center'>
          <Group>
            <Text c='red'>{formatError(saveError)}</Text>
            {/* <Button variant='subtle' size='compact-md'>Retry</Button> */}
            <Anchor href='#' onClick={() => saveTemplate(template!)}>Retry</Anchor>
          </Group>
        </Stack>
      }

      {/* Home link */}
      <Anchor size='sm' href='#' onClick={() => navigate(`/list`)}>
        <Group gap='0.2rem'>
          <IconChevronLeft size={18} />
          Back to Templates
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
            <Content
              template={template}
              setTemplate={setTemplateAndSave}
              resetTemplate={resetTemplateAndSave}
              saving={isSaving}
              dirty={dirty}
            />
          </>
        )
      })()}
    </Stack>
  )
}

function Content({ template, setTemplate, resetTemplate, saving, dirty }: {
  template: WsTemplate
  setTemplate: React.Dispatch<React.SetStateAction<WsTemplate | null>>
  resetTemplate: () => void
  saving: boolean
  dirty: boolean
}) {
  const editModal = useModal(EditMetadataModal)
  const confirmModal = useModal(ConfirmModal)

  function handleEdit() {
    editModal.open({
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
  }

  function handleReset() {
    confirmModal.open({
      message: 'Discard changes made to the template?',
      actions: [
        {
          label: 'Discard Changes',
          role: 'destructive',
          handler: resetTemplate
        }
      ]
    })
  }

  const setData: Dispatch<ReduceState<[WsTemplate.Supplier[], WsTemplate.Section[]]>> = (fn) => {
    setTemplate(template => {
      const [suppliers, sections] = fn([template!.suppliers, template!.sections])

      return { ...template!, suppliers, sections }
    })
  }

  return (
    <Stack gap='lg'>
      {/* Metadata + Save loader */}
      <Group align='flex-start'>
        {/* Metadata + Edit button */}
        <Stack w='100%' gap='xs' align='flex-start' mr='auto'>
          {/* Title + Edit button + Saving loader + Reset button */}
          <Group w='100%' gap='md' align='baseline' bg='dark.9'>
            <Title order={3} c='gray.1'>{template!.name}</Title>
            <Button variant='light' size='compact-xs' onClick={handleEdit}>
              <Group gap='0.25rem'>
                <IconPencil size={14} />
                Edit
              </Group>
            </Button>

            <Group ml='auto' align='baseline'>
              {/* Save loader -- probably not necessary */}
              {/* {<Loader size='xs' />} */}
              {/* <Text size='sm' c='dark.3'>Saving...</Text> */}
              
              {/* Reset button */}
              {
                dirty && 
                <Anchor size='sm' href='#' onClick={handleReset}>Discard Changes</Anchor>
                // <Button
                //   variant='subtle'
                //   size='compact-sm'
                //   disabled={!dirty}
                //   // leftSection={<IconX size={16} />}
                //   onClick={handleReset}
                // >
                //   Discard Changes
                // </Button>
              }
            </Group>
          </Group>
          {/* Code, items per page */}
          <Stack gap='0'>
            <Text>Code: {template.code}</Text>
            <Text>Email Recipients: {template.emailRecipients.join(', ')}</Text>
          </Stack>
        </Stack>

      </Group>

      {/* Items editor */}
      <ContentEditor
        suppliers={template.suppliers}
        sections={template.sections}
        setData={setData}
      />

      {/* Bottom bar */}
      {/* Spacers (<Box />es) have same bg color as AppShell.Main */}
      {/* <div className='sticky bottom-0 w-full pb-safe'>
        <Stack gap='0'>
          <Box h='12px' bg='dark.9' />
          <Paper p='md'>
            <Group>
              <Button variant='default' ml='auto'>Discard Changes</Button>
              <Button variant='filled'>Save Changes</Button>
            </Group>
          </Paper>
          <Box h='12px' bg='dark.9'/>
        </Stack>
      </div> */}

      {/* Modals */}
      {editModal.element}
      {confirmModal.element}

    </Stack>
  )
}