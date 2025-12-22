import { useParams } from 'react-router'
import { useQuery } from '@tanstack/react-query'
import { ActionIcon, Box, Container, Divider, Group, MantineProvider, Stack, Text, Title, useComputedColorScheme, useMantineColorScheme } from '@mantine/core'
import { IconMoon, IconSun } from '@tabler/icons-react'
import { format } from 'date-fns'

import { useApi } from 'src/app/contexts'
import theme from './mantine-theme'
import { QuizResponse, QuizResponsePayload } from 'src/quiz-app/models/QuizResponse'
import formatError from 'src/common/format-error'
import ItemResponseComponent from './ItemResponseComponent'
import { localStorageColorSchemeManager } from 'src/utils/mantine-local-storage-color-scheme-manager'

export default function QuizResponsePage() {
  const { axios } = useApi()
  const { id } = useParams()

  const { data, error, isLoading } = useQuery<QuizResponse>({
    queryKey: ['quiz-response', id],
    queryFn: async () => {
      if (!id) {
        throw new Error('Invalid ID')
      }

      const payload = (await axios.get<QuizResponsePayload>(`/quiz-response/${id}`)).data

      const data: QuizResponse = {
        ...payload,
        createdDate: new Date(payload.createdDate),
        submittedDate: new Date(payload.submittedDate)
      }

      return data
    }
  })

  return (
    <MantineProvider
      colorSchemeManager={localStorageColorSchemeManager({ key: 'fohtest-viewer-color-scheme-value' })}
      defaultColorScheme='light'
      theme={theme}
    >
      <title>
        {'FOH Test' + (data ? (' | ' + data.respondent.name) : '')}        
      </title>

      <Container p='md'>
        {(() => {
          if (isLoading) {
            return <Text>Loading...</Text>
          }

          if (error) {
            return <Text c='red'>{formatError(error)}</Text>
          }

          return (
            <>
              
              <Content data={data!} />
            </>
          )
        })()}
      </Container>
    </MantineProvider>
  )
}

function Content({ data }: { data: QuizResponse }) {
  const { toggleColorScheme } = useMantineColorScheme()
  const computedColorScheme = useComputedColorScheme('light', { getInitialValueInEffect: true })

  return (
    <Stack gap='md'>
      {/* Title */}
      <Group>
        <Title order={2} mr='auto'>{data.quiz.name}</Title>
        <ActionIcon
          variant='default' size='lg' c='gray.5'
          onClick={() => toggleColorScheme()}
        >
          {computedColorScheme == 'light' ?
            <IconMoon size={20} strokeWidth={1.5} /> :
            <IconSun size={20} strokeWidth={1.5} />
          }
        </ActionIcon>
      </Group>

      <Divider />

      {/* Name + Store */}
      <Stack gap='0.5rem'>
        <Group>
          <Text fw='bold'>Name</Text>
          <Text>{data.respondent.name}</Text>
        </Group>
        <Group>
          <Text fw='bold'>Store</Text>
          <Text>{data.respondent.store}</Text>
        </Group>
        <Group>
          <Text fw='bold'>Date</Text>
          <Text>{format(data.submittedDate, "EEEE, d MMM yyyy, h:mm aaa")}</Text>
        </Group>
      </Stack>

      <Divider />

      {/* Sections */}
      {data.quiz.sections.map((section, sectionIndex) => {
        return (
          <Stack key={section.id} gap='md'>
            {section.rows.map((row, rowIndex) => {
              return (
                <Group key={rowIndex} wrap='nowrap' align='flex-start'>
                  <Text fw='bold' w='1rem'>{rowIndex + 1}.</Text>
                  {(() => {
                    const item = data.quiz.items.find(x => x.id == row.itemId)

                    if (!item) {
                      return <Text c='red'>Item Not Found</Text>
                    }

                    const itemResponse = data.itemResponses.find(x => x.itemId == item.id)

                    if (!itemResponse) {
                      return <Text c='red'>Item Response Not Found</Text>
                    }

                    return <ItemResponseComponent item={item} itemResponse={itemResponse} />
                  })()}
                </Group>
              )

            })}
          </Stack>
        )
      })}

      <Box h='3rem' />
    </Stack>
  )
}