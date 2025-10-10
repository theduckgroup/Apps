import { useEffect, useRef, useState } from "react"
import { ActionIcon, Box, Button, Group, HoverCard, List, Modal, Select, Stack, Text, Textarea } from "@mantine/core"
import { Quiz } from 'src/quiz-app/models/Quiz'

import ListItemEditor from './ListItemEditor'
import SelectedResponseItemEditor from './SelectedResponseItemEditor'
import TextInputItemEditor from './TextInputItemEditor'
import { getHotkeyHandler, useHotkeys } from '@mantine/hooks'
import { IconInfoCircle, IconQuestionMark } from '@tabler/icons-react'

export default function EditItemModal({ opened, close, options }: {
  opened: boolean,
  close: () => void,
  options: EditItemModalOptions | null
}) {
  if (options) {
    return <EditItemModalImpl opened={opened} close={close} options={options} />
  } else {
    return null
  }
}

function EditItemModalImpl({ opened, close, options }: {
  opened: boolean,
  close: () => void,
  options: EditItemModalOptions
}) {
  const [item, setItem] = useState<Quiz.Item>(options.item)
  const ref = useRef<HTMLDivElement | null>(null)

  const title = (() => {
    switch (item.kind) {
      case 'selectedResponseItem': return 'Multiple Choice Item'
      case 'textInputItem': return 'Text Input Item'
      case 'listItem': return 'List Item'
    }
  })()

  function handleSave() {
    close()
    options.onSave(item)
  }

  // useEffect(() => {
  //   const element = ref.current
  //   const handler = getHotkeyHandler([['mod+Enter', handleSave]])

  //   setTimeout(() => {
  //     element?.addEventListener('keydown', handler)
  //   }, 500)

  //   return () => element?.removeEventListener('keydown', handler)
  // })

  return (
    <Modal
      opened={opened}
      onClose={close}
      title={title}
      size='lg'
      returnFocus={false}
      closeOnClickOutside={false}
    >
      <Stack ref={ref}>
        {
          (() => {
            switch (item.kind) {
              case 'listItem':
                return <ListItemEditor item={item} onChange={setItem} />

              case 'selectedResponseItem':
                return <SelectedResponseItemEditor item={item} onChange={setItem} />

              case 'textInputItem':
                return <TextInputItemEditor item={item} onChange={setItem} />
            }
          })()
        }
        <Group>
          {/* <HoverCard width={250} shadow='md'>
            <HoverCard.Target>
              <ActionIcon variant='transparent'>
                <IconInfoCircle size={20} />
              </ActionIcon>
            </HoverCard.Target>
            <HoverCard.Dropdown>
              <Text size='sm'>
                Use Ctrl+Enter or ⌘+Enter to save, Esc to cancel
              </Text>
            </HoverCard.Dropdown>
          </HoverCard> */}
          <Group gap='sm' ml='auto'>
            <Button variant='default' w='6rem' onClick={close}>Cancel</Button>
            <Button type='submit' w='6rem' onClick={handleSave}>Save</Button>
          </Group>
        </Group>
      </Stack>
    </Modal>
  )
}

export interface EditItemModalOptions {
  title: string
  item: Quiz.Item
  onSave: (_: Quiz.Item) => void
}