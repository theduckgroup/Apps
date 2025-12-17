import { useEffect } from 'react'
import { ActionIcon, Button, Grid, Group, Menu, Paper, Stack, Text, Title } from '@mantine/core'
import { IconDots, IconPencil, IconPlus } from '@tabler/icons-react'
import { useQuery } from '@tanstack/react-query'

import { usePath, useApi } from 'src/app/contexts'
import { WsTemplateMetadata } from 'src/ws-app/models/WsTemplate'
import eventHub from 'src/ws-app/event-hub'
import formatError from 'src/common/format-error'
import useModal from 'src/utils/use-modal'
import { ConfirmModal } from 'src/utils/ConfirmModal'

const TemplateListPage = () => {
  const { axios } = useApi()

  const { data, error, isLoading, refetch } = useQuery({
    queryKey: ['wsTemplates'],
    queryFn: async () => ((await axios.get('/templates/meta')).data as WsTemplateMetadata[])
  })

  useEffect(() => {
    const unsub = eventHub.onTemplatesChanged(() => {
      refetch()
    })

    return unsub
  }, [refetch])

  return (
    <Stack gap='md' align='flex-start'>
      <title>Weekly Spending | The Duck Group</title>
      <Title order={2} c='gray.0'>Templates</Title>
      {(() => {
        if (isLoading) {
          return <Text>Loading...</Text>
        }

        if (error) {
          return <Text c='red'>{formatError(error)}</Text>
        }
        
        if (!data) {
          return <Text>???</Text>
        }

        return <Content data={data} />
      })()}
    </Stack>
  )
}

function Content({ data }: {
  data: WsTemplateMetadata[]
}) {
  const { navigate } = usePath()
  const confirmModal = useModal(ConfirmModal)

  return (
    <Stack align='flex-start' w='100%'>
      <Grid w='100%'>
        {
          data
            .sort((x, y) => x.name.localeCompare(y.name))
            .map(template => (
              <TemplateListItem
                key={template.id}
                template={template}
                openConfirmModal={confirmModal.open}
              />
            ))
        }
      </Grid>
      {
        import.meta.env.DEV &&
        <Button
          variant='default'
          leftSection={<IconPlus size={16} strokeWidth={2} />}
          onClick={() => navigate('/template')}
        >
          [dev] Add Template
        </Button>
      }
      {/* Modals */}
      {confirmModal.element}
    </Stack>
  )
}

function TemplateListItem({ template, openConfirmModal }: {
  template: WsTemplateMetadata,
  openConfirmModal: (_: ConfirmModal.Options) => void
}) {
  const { axios } = useApi()
  const { navigate } = usePath()

  const handleDuplicate = () => {
    openConfirmModal({
      title: '',
      message: 'Duplicate this template?',
      actions: [{
        label: 'Duplicate',
        handler: async () => {
          return await axios.post(`templates/${template.id}/duplicate`)
        }
      }]
    })
  }

  const handleDelete = () => {
    openConfirmModal({
      title: '',
      message: (
        <Stack>
          <Text>Delete '{template.name}'?</Text>
          <Text fw='bold'>This cannot be undone.</Text>
        </Stack>
      ),
      actions: [{
        label: 'Delete',
        role: 'destructive',
        handler: async () => {
          return await axios.delete(`templates/${template.id}`)
        }
      }]
    })
  }

  return (
    <Grid.Col span={{ base: 12, sm: 6, md: 4 }}>
      <Paper px='md' py='sm' bg='dark.8' withBorder>
        <Stack align='flex-start' gap='md'>
          {/* Title + Code */}
          <Stack gap='0.25rem'>
            <Title order={5}>{template.name}</Title>
            <Stack gap='0'>
              {<Text fz='sm' fw={500} opacity={0.5}> {template.code.length > 0 ? template.code : '[No Code]'}</Text>}
              <Text fz='sm'>{template.supplierCount} suppliers</Text>
            </Stack>
          </Stack>

          <Group w='100%'>
            {/* View/Edit button */}
            <Button
              variant='light'
              size='xs'
              // leftSection={<IconPencil size={14}/>}
              // rightSection={<IconArrowNarrowRight size={14}/>}
              onClick={() => navigate(`/template/${template.id}`)}
            >
              View/Edit
            </Button>
            {/* Dropdown menu */}
            {
              import.meta.env.DEV &&
              <Menu position='bottom-end' width={150}>
                <Menu.Target>
                  <ActionIcon variant='default' ml='auto'>
                    <IconDots size={16} />
                  </ActionIcon>
                </Menu.Target>
                <Menu.Dropdown>
                  <Menu.Item onClick={handleDuplicate}>Duplicate</Menu.Item>
                  <Menu.Item onClick={handleDelete}>Delete</Menu.Item>
                </Menu.Dropdown>
              </Menu>
            }
          </Group>
        </Stack>
      </Paper>
    </Grid.Col>
  )
}

export default TemplateListPage