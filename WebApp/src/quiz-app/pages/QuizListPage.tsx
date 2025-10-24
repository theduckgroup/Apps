import { useEffect } from 'react'
import { ActionIcon, Button, Grid, Group, Menu, Paper, Stack, Text, Title } from '@mantine/core'
import { IconDots, IconPlus } from '@tabler/icons-react'
import { useQuery } from '@tanstack/react-query'

import { usePath, useApi } from 'src/app/contexts'
import { QuizMetadata } from 'src/quiz-app/models/Quiz'
import quizEventHub from 'src/quiz-app/event-hub'
import formatError from 'src/common/format-error'
import useModal from 'src/utils/use-modal'
import { ConfirmModal } from 'src/utils/ConfirmModal'

const QuizListPage = () => {
  const { axios } = useApi()

  const { data, error, isLoading, refetch } = useQuery({
    queryKey: ['quizzes'],
    queryFn: async () => {
      const metaquizzes = (await axios.get('/quizzes')).data as QuizMetadata[]
      return metaquizzes
    }
  })

  useEffect(() => {
    const unsub = quizEventHub.onQuizzesChanged(() => {
      refetch()
    })

    return unsub
  }, [refetch])

  return (
    <Stack gap='md' align='flex-start'>
      <Title order={2} c='gray.0'>Tests</Title>
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
  data: QuizMetadata[]
}) {
  const { navigate } = usePath()
  const confirmModal = useModal(ConfirmModal)

  return (
    <Stack align='flex-start' w='100%'>
      <Grid w='100%'>
        {
          data.map(metaquiz => (
            <QuizComponent
              key={metaquiz.id}
              metaquiz={metaquiz}
              openConfirmModal={confirmModal.open}
            />
          ))
        }
      </Grid>
      {
        import.meta.env.DEV &&
        <Button
          variant='filled'
          leftSection={<IconPlus size={16} strokeWidth={2} />}
          onClick={() => navigate('/quiz')}
        >
          [dev] Add Test
        </Button>
      }
      {/* Modals */}
      {confirmModal.element}
    </Stack>
  )
}

function QuizComponent({ metaquiz, openConfirmModal }: {
  metaquiz: QuizMetadata,
  openConfirmModal: (_: ConfirmModal.Options) => void
}) {
  const { axios } = useApi()
  const { navigate } = usePath()

  function handleDuplicate() {
    openConfirmModal({
      title: '',
      message: 'Duplicate this quiz?',
      actions: [{
        label: 'Duplicate',
        handler: async () => {
          return await axios.post(`quiz/${metaquiz.id}/duplicate`)
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
            <Title order={5}>{metaquiz.name}</Title>
            <Stack gap='0'>
              {<Text fz='sm' fw={500} opacity={0.5}> {metaquiz.code.length > 0 ? metaquiz.code : '[No Code]'}</Text>}
              <Text fz='sm'>{metaquiz.itemCount} items</Text>
            </Stack>
          </Stack>

          <Group w='100%'>
            {/* View/Edit button */}
            <Button
              variant='default'
              size='xs'
              // leftSection={<IconPencil size={14}/>}
              // rightSection={<IconArrowNarrowRight size={14}/>}
              onClick={() => navigate(`/quiz/${metaquiz.id}`)}
            >
              <Group gap='0.25rem' align='center'>
                {/* <IconPencil size={14} strokeWidth={1.25} /> */}
                View/Edit
                {/* <IconArrowNarrowRight size={14} /> */}
              </Group>
            </Button>
            {/* Dropdown menu */}
            {
              import.meta.env.DEV &&
              <Menu position='bottom-end' width={150}>
                <Menu.Target>
                  <ActionIcon
                    variant='default'
                    ml='auto'
                  >
                    <IconDots size={16} />
                  </ActionIcon>
                </Menu.Target>
                <Menu.Dropdown>
                  <Menu.Item onClick={handleDuplicate}>
                    Duplicate
                  </Menu.Item>
                </Menu.Dropdown>
              </Menu>
            }
          </Group>
        </Stack>
      </Paper>
    </Grid.Col>
  )
}

export default QuizListPage