import { Box, Divider, Flex, Group, Paper, Stack, Text } from '@mantine/core'
import { IconProps, IconSquare, IconSquareCheckFilled, IconSquareFilled } from '@tabler/icons-react'
import { createElement } from 'react'
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
  return (
    <Stack w='100%' gap='0.4rem'>
      <Text fz='sm' mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
      <Flex gap='md' wrap='wrap' rowGap='0.5rem'>
        {
          item.data.options.length > 0 ?
            item.data.options.map(option => {
              const selected = itemResponse.data.selectedOptions.some(x => x.id == option.id)
              const icon = selected ? IconSquare : IconSquareCheckFilled

              const iconProps: IconProps = {
                size: 14,
                strokeWidth: 1.5,
                className: 'flex-none translate-y-0.5'
              }

              return (
                <Group key={option.id} gap='0.45rem' wrap='nowrap' align='baseline'>
                  {createElement(icon, iconProps)}
                  <Text fz='sm' className='whitespace-pre-wrap'>{option.value}</Text>
                </Group>
              )              
            })
            :
            (
              <Text c='red'>(No option)</Text>
            )
        }
      </Flex>
    </Stack>
  )
}

function TextInputItemResponseComponent({ item, itemResponse }: {
  item: Quiz.TextInputItem,
  itemResponse: QuizResponse.TextInputItemResponse
}) {
  return (
    <Stack w='100%' gap='0.25rem'>
      <Text fz='sm' mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
      <Stack w='45%' gap='0'>
        <Text fz='sm' opacity={0}>(Text)</Text>
        <Divider />
      </Stack>
    </Stack>
  )
}

function ListItemResponseComponent({ item, itemResponse }: {
  item: Quiz.ListItem,
  itemResponse: QuizResponse.ListItemResponse
}) {
  return (
    <Stack w='100%' gap='0.5rem'>
      <Text fz='sm' mr='auto' className='whitespace-pre-wrap'>{item.data.prompt}</Text>
      <Stack gap='0.4rem'>
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
                {/* {(() => {
                  switch (subitem.kind) {
                    case 'selectedResponseItem':
                      if (subitemResponse.itemKind != 'selectedResponseItem') {
                        return <Error />
                      }

                      return <SelectedResponseItemResponseComponent item={subitem} itemResponse={subitemResponse} />

                    case 'textInputItem':
                      if (subitemResponse.itemKind != 'textInputItem') {
                        return <Error />
                      }

                      return <TextInputItemResponseComponent item={subitem} itemResponse={subitemResponse} />

                    case 'listItem':
                      if (subitemResponse.itemKind != 'listItem') {
                        return <Error />
                      }

                      return <ListItemResponseComponent item={item} itemResponse={subitemResponse} />
                  }
                })()} */}
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