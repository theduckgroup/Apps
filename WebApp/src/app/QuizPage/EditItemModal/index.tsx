import { useEffect, useRef, useState } from "react"
import { Button, Group, Modal, Select, Stack, Textarea } from "@mantine/core"
import { Quiz } from 'src/models/Quiz'

import ListItemEditor from './ListItemEditor'
import SelectedResponseItemEditor from './SelectedResponseItemEditor'
import TextInputItemEditor from './TextInputItemEditor'

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

  return (
    <Modal
      opened={opened}
      onClose={close}
      title={title}
      size='lg'
      returnFocus={false}
      closeOnClickOutside={false}
    >
      <Stack>
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
        <Group gap='sm' ml='auto'>
          <Button variant='default' w='6rem' onClick={close}>Cancel</Button>
          <Button type='submit' w='6rem' onClick={handleSave}>Save</Button>
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