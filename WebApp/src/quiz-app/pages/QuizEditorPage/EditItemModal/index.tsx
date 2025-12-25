import { useRef, useState } from 'react'
import { Button, Group, Modal, Stack } from '@mantine/core'
import { Quiz } from 'src/quiz-app/models/Quiz'

import ListItemEditor from './ListItemEditor'
import SelectedResponseItemEditor from './SelectedResponseItemEditor'
import TextInputItemEditor from './TextInputItemEditor'
import { produce } from 'immer'

export function EditItemModal({ opened, onClose, options }: {
  opened: boolean,
  onClose: () => void,
  options: {
    title: string
    item: Quiz.Item
    onSave: (_: Quiz.Item) => void
  }
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

  const isValid = (() => {
    switch (item.kind) {
      case 'selectedResponseItem': {
        return item.data.prompt != '' && item.data.options.filter(x => x.value != '').length > 0
      }
      case 'textInputItem': {
        return item.data.prompt != ''
      }
      case 'listItem': {
        return item.data.items.some(x => x.data.prompt != '')
      }
    }
  })()

  function handleSave() {
    // Sanitize data
    const sanitizedItem = produce(item, item => {
      if (item.kind == 'selectedResponseItem') {
        item.data.options = item.data.options.filter(x => x.value != '')
      }
    })

    onClose()
    options.onSave(sanitizedItem)
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
      onClose={onClose}
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
            <Button variant='default' w='6rem' onClick={onClose}>Cancel</Button>
            <Button type='submit' w='6rem' disabled={!isValid} onClick={handleSave}>Save</Button>
          </Group>
        </Group>
      </Stack>
    </Modal>
  )
}