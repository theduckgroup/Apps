import { Flex, Group, Paper, Stack, Text } from '@mantine/core'
import { IconSquare, IconSquareFilled } from '@tabler/icons-react'
import { Quiz } from 'src/models/Quiz'

/**
 * Readonly component for an item
 */
export default function ReadonlyItemComponent({ item, controlSection }: {
  item: Quiz.Item,
  controlSection?: React.ReactElement
}) {
  switch (item.kind) {
    case 'selectedResponseItem':
      return <SelectedResponseItemComponent item={item} controlSection={controlSection} />

    case 'textInputItem':
      return <TextInputItemComponent item={item} controlSection={controlSection} />

    case 'listItem':
      return <ListItemComponent item={item} controlSection={controlSection} />
  }
}

function SelectedResponseItemComponent({ item, controlSection }: {
  item: Quiz.SelectedResponseItem,
  controlSection?: React.ReactElement
}) {
  return (
    <Stack w='100%' gap='0.2rem'>
      <PromptComponent prompt={item.data.prompt} controlSection={controlSection} />
      <Flex gap='md'>
        {
          item.data.options.length > 0 ?
            item.data.options.map(option => (
              <Group key={option.id} gap='0.33rem'>
                <IconSquare size={14} strokeWidth={1.5} />
                <Text fz='sm'>{option.value}</Text>
              </Group>
            )) : (
              <Text c='red'>(No option)</Text>
            )
        }
      </Flex>
    </Stack>
  )
}

function TextInputItemComponent({ item, controlSection }: {
  item: Quiz.TextInputItem,
  controlSection?: React.ReactElement
}) {
  return (
    <Stack w='100%' gap='0.25rem'>
      <PromptComponent prompt={item.data.prompt} controlSection={controlSection} />
      <Paper w='35%' px='sm' py='0.4rem' bg='dark.6'>
        <Text fz='sm' c='dark.3'>Text</Text>
      </Paper>
      {/* <TextInput
        variant='filled'
        size='sm'
        w='50%'
        value=''
        placeholder='Text'
        className='pointer-events-none select-none'
      /> */}
    </Stack>
  )
}

function ListItemComponent({ item, controlSection }: {
  item: Quiz.ListItem,
  controlSection?: React.ReactElement
}) {
  return (
    <Stack w='100%' gap='0'>
      <PromptComponent prompt={item.data.prompt} controlSection={controlSection} />
      <Stack gap='0.3rem'>
        {
          item.data.items.map(subitem => {
            return (
              <Group key={subitem.id} gap='sm' align='baseline' wrap='nowrap'>
                <IconSquareFilled size={5} className='-translate-y-0.5' />

                {(() => {
                  switch (subitem.kind) {
                    case 'selectedResponseItem':
                      return <SelectedResponseItemComponent item={subitem} />

                    case 'textInputItem':
                      return <TextInputItemComponent item={subitem} />

                    case 'listItem':
                      return <ListItemComponent item={item} />
                  }
                })()}
              </Group>
            )

          })
        }
      </Stack>
    </Stack>
  )
}

function PromptComponent({ prompt, controlSection }: {
  prompt: string,
  controlSection?: React.ReactElement
}) {
  return (
    <Group gap='md' wrap='nowrap' w='100%' align='start'>
      <Text fz='sm' mr='auto'>{prompt}</Text>
      {controlSection}
    </Group>
  )
}