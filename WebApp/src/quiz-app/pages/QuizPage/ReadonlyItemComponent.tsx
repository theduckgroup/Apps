import { Divider, Group, Stack, Text } from '@mantine/core'
import { IconSquare, IconSquareFilled } from '@tabler/icons-react'
import { Quiz } from 'src/quiz-app/models/Quiz'

/**
 * Readonly component for an item
 */
export default function ReadonlyItemComponent({ item, controlSection }: {
  item: Quiz.Item,
  controlSection?: React.ReactElement
}) {
  return (
    <Group gap='md' wrap='nowrap' w='100%' align='flex-start'>
      {(() => {
        switch (item.kind) {
          case 'selectedResponseItem':
            return <SelectedResponseItemComponent item={item} />

          case 'textInputItem':
            return <TextInputItemComponent item={item} />

          case 'listItem':
            return <ListItemComponent item={item} />
        }
      })()}
      {controlSection}
    </Group>
  )
}

function SelectedResponseItemComponent({ item }: {
  item: Quiz.SelectedResponseItem
}) {
  return (
    <Stack w='100%' gap='0.4rem'>
      <Text mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
      <Stack gap='0.5rem'>
        {
          item.data.options.length > 0 ?
            item.data.options.map(option => (
              <Group key={option.id} gap='0.45rem' wrap='nowrap' align='baseline'>
                <IconSquare size={16} strokeWidth={1.5} className='flex-none translate-y-[0.15rem]' />
                <Text className='whitespace-pre-wrap'>{option.value}</Text>
              </Group>
            )) :
            (
              <Text c='red'>(No option)</Text>
            )
        }
      </Stack>
    </Stack>
  )
}

function TextInputItemComponent({ item }: {
  item: Quiz.TextInputItem
}) {
  switch (item.data.layout) {
    case 'inline':
      return (
        <Stack w='100%' gap='0.25rem'>
          <Text mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
          <Stack w='45%' gap='0'>
            <Text opacity={0}>(Text)</Text>
            <Divider />
          </Stack>
        </Stack>
      )
    case 'stack':
      return (
        <Group w='100%' align='flex-end' gap='md'>
          <Text className='whitespace-pre-wrap'>{item.data.prompt}</Text>
          <Divider miw='40%'/>
        </Group>
      )
  }
}

function ListItemComponent({ item }: {
  item: Quiz.ListItem
}) {
  return (
    <Stack w='100%' gap='0.5rem'>
      <Text mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
      <Stack gap='0.4rem'>
        {
          item.data.items.map(subitem => (
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
          ))}
      </Stack>
    </Stack>
  )
}