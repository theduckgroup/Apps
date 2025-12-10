import { produce } from 'immer'
import { Button, Checkbox, Group, Modal, Stack, Textarea } from '@mantine/core'

import { WsTemplate } from 'src/ws-app/models/WsTemplate'
import { useEffect, useRef, useState } from 'react'


export function EditSupplierModal({ opened, onClose, options }: {
  opened: boolean,
  onClose: () => void,
  options: {
    title: string,
    supplier: WsTemplate.Supplier,
    onSave: (_: WsTemplate.Supplier) => void
  }
}) {
  const { onSave } = options
  const [supplier, setSupplier] = useState(options.supplier)
  
  const nameRef = useRef<HTMLTextAreaElement | null>(null)

  const handleNameChange = (value: string) => {
    setSupplier(produce(supplier, supplier => {
      supplier.name = value
    }))
  }

  const handleSave = () => {
    onSave(supplier)
  }

  // function handleInlineChange(value: boolean) {
  //   const modifiedItem = produce(item, item => {
  //     item.name.layout = value ? 'inline' : 'stack'
  //   })

  //   onChange(modifiedItem)
  // }

  useEffect(() => {
    setTimeout(() => {
      nameRef.current?.focus()
    }, 50)
  }, [nameRef])

  const isValid = supplier.name != ''

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={options.title}
      size='lg'
      returnFocus={false}
      closeOnClickOutside={false}
    >
      <Stack>
        <Textarea
          label='Supplier Name'
          data-autofocus={true}
          autosize
          required
          value={supplier.name}
          onChange={e => handleNameChange(e.currentTarget.value)}
          ref={nameRef}
        />
        {/* <Checkbox
        label='Inline'
        checked={item.data.layout == 'inline'}
        onChange={e => handleInlineChange(e.currentTarget.checked)}
      /> */}
      </Stack>
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
    </Modal>
  )
}
