import { Button, Group, Modal, Stack, TextInput } from "@mantine/core"
import { isNotEmpty, useForm } from "@mantine/form"
import { InvStore } from 'src/inventory-app/models/InvStore'

export function EditSectionModal({ opened, onClose, options }: {
  opened: boolean,
  onClose: () => void,
  options: {
    title: string
    section: InvStore.Section,
    onSave: (_: InvStore.Section) => void
  }
}) {
  const { title, section, onSave } = options

  const form = useForm({
    mode: 'controlled',
    initialValues: {
      name: section.name
    },
    validate: {
      name: isNotEmpty('Name is required')
    }
  })

  function handleSubmit(values: typeof form.values) {
    onClose()

    onSave({
      ...section,
      name: values.name.trim()
    })
  }

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={title}
      returnFocus={false}
      closeOnClickOutside={false}
    >
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack>
          <TextInput
            label='Name'
            key={form.key('name')}
            data-autofocus
            {...form.getInputProps('name')}
          />
          <Group gap='xs' ml='auto'>
            <Button variant='default' onClick={onClose} w='6rem'>Cancel</Button>
            <Button type='submit' w='6rem'>Save</Button>
          </Group>
        </Stack>
      </form>
    </Modal>
  )
}

// export interface EditSectionModalOptions {
//   title: string
//   fields: {
//     name: string
//   }
//   onSave: (fields: { name: string }) => void
// }

// export namespace EditSectionModalOptions {
//   export const empty: EditSectionModalOptions = {
//     title: '',
//     fields: { name: '' },
//     onSave: () => { }
//   }
// }
