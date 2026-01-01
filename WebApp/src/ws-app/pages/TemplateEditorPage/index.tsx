import { useEffect, useMemo, useRef, useState } from 'react'
import { useBlocker, useParams } from 'react-router'
import { Anchor, Button, Group, Stack, Text, Title } from '@mantine/core'
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
import { ConfirmModal } from 'src/utils/ConfirmModal'
import { EditorFooter } from 'src/utils/EditorFooter'

export default function TemplateEditorPage() {
  const { templateId } = useParams()
  const { axios } = useApi()
  const { navigate } = usePath()

  const [template, setTemplate] = useState<WsTemplate | null>(null)
  const [didChange, setDidChange] = useState(false) // Whether user made changes or not
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false) // Whether there is pending changes
  const blocker = useBlocker(useMemo(() => hasUnsavedChanges, [hasUnsavedChanges]))
  const mainRef = useRef<HTMLDivElement>(null)

  // Load

  const { mutate: loadTemplate, error: loadError, isPending: isLoading } = useMutation({
    mutationFn: async () => {
      if (templateId) {
        return (await axios.get<WsTemplate>(`/templates/${templateId}`)).data

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

  // Save

  const { mutate: saveTemplate, error: saveError, isPending: saving } = useMutation({
    mutationFn: async (template: WsTemplate) => {
      await axios.put(`/templates/${template.id}`, template)
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
            Back to Templates
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

          if (!template) {
            return <>???</>
          }

          return (
            <>
              <title>{template.name + ' | The Duck Group'}</title>
              <MetaAndContent
                template={template}
                setTemplate={valueOrReducer => {
                  setTemplate(valueOrReducer)
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
          save={() => saveTemplate(template!)}
          isSaving={saving}
          hasUnsavedChanges={hasUnsavedChanges}
          saveError={saveError}
        />
      }

      <ConfirmModal
        opened={blocker.state == 'blocked'}
        onClose={() => blocker.reset!()}
        options={{
          title: 'Confirm',
          message: 'You have unsaved changes. Discard?',
          actions: [
            {
              label: 'Cancel',
              role: 'cancel',
              handler: () => blocker.reset!()
            },
            {
              label: 'Discard',
              role: 'destructive',
              handler: () => blocker.proceed!()
            }
          ]
        }}
      />
    </>
  )
}

/**
 * Template meta (name, code etc) and content (items and sections).
 */
function MetaAndContent({ template, setTemplate }: {
  template: WsTemplate
  setTemplate: React.Dispatch<React.SetStateAction<WsTemplate | null>>
}) {
  const editModal = useModal(EditMetadataModal)

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

  type Reducer<T> = (prev: T) => T

  const setData = (fn: Reducer<[WsTemplate.Supplier[], WsTemplate.Section[]]>) => {
    setTemplate(template => {
      const [suppliers, sections] = fn([template!.suppliers, template!.sections])

      return { ...template!, suppliers, sections }
    })
  }

  return (
    <Stack className='w-full' gap='md'>
      {/* Title + Edit button */}
      <Group w='100%' gap='md' align='baseline'>
        <Title order={2} c='gray.1'>{template.name}</Title>
        <Button variant='light' size='compact-xs' fw='normal' onClick={handleEdit}>
          <Group gap='0.25rem'>
            <IconPencil size={13} />
            Edit
          </Group>
        </Button>
      </Group>

      {/* Code, email recipients */}
      <Stack gap='0'>
        <Text>Code: {template.code}</Text>
        <Text>Email Recipients: {template.emailRecipients.join(', ')}</Text>
      </Stack>

      {/* Items editor */}
      <ContentEditor
        suppliers={template.suppliers}
        sections={template.sections}
        setData={setData}
      />

      {/* Modals */}
      {editModal.element}
    </Stack>
  )
}