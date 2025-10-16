import { Divider, Group, Stack, Text, useMantineColorScheme } from '@mantine/core'
import { useViewportSize } from '@mantine/hooks'
import { IconCheckbox, IconSquare, IconSquareCheck, IconSquareCheckFilled, IconSquareFilled, IconSquareRoundedCheckFilled } from '@tabler/icons-react'
import { CheckSquareIcon, SquareIcon } from '@phosphor-icons/react'
import { Quiz } from 'src/quiz-app/models/Quiz'
import { QuizResponse } from 'src/quiz-app/models/QuizResponse'

export default function ItemResponseComponent({ item, itemResponse }: {
  item: Quiz.Item,
  itemResponse: QuizResponse.ItemResponse
}) {
  switch (item.kind) {
    case 'selectedResponseItem':
      if (itemResponse.itemKind != 'selectedResponseItem') {
        return <Error />
      }

      return <SelectedResponseItemResponseComponent item={item} itemResponse={itemResponse} />

    case 'textInputItem':
      if (itemResponse.itemKind != 'textInputItem') {
        return <Error />
      }

      return <TextInputItemResponseComponent item={item} itemResponse={itemResponse} />

    case 'listItem':
      if (itemResponse.itemKind != 'listItem') {
        return <Error />
      }

      return <ListItemResponseComponent item={item} itemResponse={itemResponse} />
  }
}

function SelectedResponseItemResponseComponent({ item, itemResponse }: {
  item: Quiz.SelectedResponseItem,
  itemResponse: QuizResponse.SelectedResponseItemResponse
}) {
  const blue = useBlueColor()

  return (
    <Stack w='100%' gap='0.4rem'>
      <Text mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
      <Stack gap='0.5rem'>
        {
          item.data.options.length > 0 ?
            item.data.options.map(option => {
              const selected = itemResponse.data.selectedOptions.some(x => x.id == option.id)

              return (
                <Group
                  key={option.id}
                  gap='0.45rem' wrap='nowrap' align='baseline'
                >
                  {selected ?
                    <Text c={blue}>
                      <CheckSquareIcon size={18} weight='fill'  className='flex-none translate-y-0.75' />
                    </Text> :
                    <Text c='gray.5'>
                      <SquareIcon size={18} weight='bold' className='flex-none translate-y-0.75' />
                    </Text>
                  }
                  < Text className='whitespace-pre-wrap'>{option.value}</Text>
                </Group>
              )
            })
            :
            (
              <Text c='red'>(No option)</Text>
            )
        }
      </Stack>
    </Stack >
  )
}

function TextInputItemResponseComponent({ item, itemResponse }: {
  item: Quiz.TextInputItem,
  itemResponse: QuizResponse.TextInputItemResponse
}) {
  const { width } = useViewportSize()
  const blue = useBlueColor()

  if (width > 480 && item.data.layout == 'inline') {
    return (
      <Group w='100%' align='flex-start'>
        <Text mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
        <Stack gap='0rem' className='grow'>
          {itemResponse.data.value.trim().length ?
            <Text c={blue}>{itemResponse.data.value}</Text> :
            <Text opacity={0}>'Z'</Text>
          }
          <Divider />
        </Stack>
      </Group>
    )
  } else {
    return (
      <Stack w='100%' gap='0.25rem'>
        <Text mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
        <Stack gap='0rem'>
          {itemResponse.data.value.trim().length ?
            <Text c={blue}>{itemResponse.data.value}</Text> :
            <Text opacity={0}>'ZZ'</Text>
          }
          <Divider />
        </Stack>
      </Stack>
    )
  }
}

function ListItemResponseComponent({ item, itemResponse }: {
  item: Quiz.ListItem,
  itemResponse: QuizResponse.ListItemResponse
}) {
  return (
    <Stack w='100%' gap='0.75rem'>
      <Text mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
      <Stack gap='0.75rem'>
        {
          item.data.items.map(subitem => {
            const subitemResponse = itemResponse.data.itemResponses.find(x => x.itemId == subitem.id)

            if (!subitemResponse) {
              return <Error />
            }

            return (
              <Group key={subitem.id} gap='sm' align='baseline' wrap='nowrap'>
                <IconSquareFilled size={5} className='-translate-y-0.5' />
                <ItemResponseComponent item={subitem} itemResponse={subitemResponse} />
              </Group>
            )
          })}
      </Stack>
    </Stack>
  )
}

function Error({ message }: {
  message?: string
}) {
  return (
    <Text c='red'>{message ?? 'Error'}</Text>
  )
}

function useBlueColor() {
  const { colorScheme } = useMantineColorScheme()
  return colorScheme === 'dark' ? '#4477FF' : '#0437F2'
}