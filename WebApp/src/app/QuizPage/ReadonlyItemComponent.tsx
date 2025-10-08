import { Box, Divider, Flex, Group, Paper, Stack, Text } from '@mantine/core'
import { IconSquare, IconSquareFilled } from '@tabler/icons-react'
import { Quiz } from 'src/models/Quiz'

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
    <Stack w='100%' gap='0.5rem'>
      <Text fz='sm' mr='auto'>{item.data.prompt}</Text>
      <Flex gap='md' wrap='wrap' rowGap='0.5rem'>
        {
          item.data.options.length > 0 ?
            item.data.options.map(option => (
              <Group key={option.id} gap='0.33rem' wrap='nowrap'>
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

function TextInputItemComponent({ item }: {
  item: Quiz.TextInputItem
}) {
  return (
    <Stack w='100%' gap='0.25rem'>
      <Text fz='sm' mr='auto'>{item.data.prompt}</Text>
      <Stack w='30%' gap='0'>
        <Text fz='sm' opacity={0}>(Text)</Text>
        <Divider />
      </Stack>
    </Stack>
  )
}

function ListItemComponent({ item }: {
  item: Quiz.ListItem
}) {
  return (
    <Stack w='100%' gap='0.5rem'>
      <Text fz='sm' mr='auto'>{item.data.prompt}</Text>
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