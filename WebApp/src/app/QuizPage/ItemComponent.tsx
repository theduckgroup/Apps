import { Flex, Group, Stack, Text, TextInput } from '@mantine/core'
import { IconCheckbox, IconSquare } from '@tabler/icons-react'
import { Quiz } from 'src/models/Quiz'

export default function ItemComponent({ item, controlSection }: {
  item: Quiz.Item,
  controlSection: React.ReactElement
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
  controlSection: React.ReactElement
}) {
  return (
    <Stack w='100%' gap='0.25rem'>
      <PromptComponent prompt={item.data.prompt} controlSection={controlSection} />
      <Flex gap='md'>
        {
          item.data.options.length > 0 ?
            item.data.options.map(option => (
              <Group gap='0.4rem'>
                <IconSquare size={16} />
                <Text>{option.value}</Text>
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
  controlSection: React.ReactElement
}) {
  return (
    <Stack w='100%' gap='sm'>
      <PromptComponent prompt={item.data.prompt} controlSection={controlSection} />
      <TextInput
        size='sm'
        w='50%'
        value=''
        placeholder='Text'
        className='pointer-events-none select-none'
      />
    </Stack>
  )
}

function ListItemComponent({ item, controlSection }: {
  item: Quiz.ListItem,
  controlSection: React.ReactElement
}) {
  return (
    <Stack w='100%'>
      <PromptComponent prompt={item.data.prompt} controlSection={controlSection} />
    </Stack>
  )
}

function PromptComponent({ prompt, controlSection }: {
  prompt: string,
  controlSection: React.ReactElement
}) {
  return (
    <Group gap='md' wrap='nowrap' w='100%' align='start'>
      <Text mr='auto'>{prompt}</Text>
      {controlSection}
    </Group>
  )
}