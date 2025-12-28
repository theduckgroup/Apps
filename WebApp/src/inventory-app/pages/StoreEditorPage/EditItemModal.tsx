import { Button, Modal, Stack, TextInput } from "@mantine/core"
import { isNotEmpty, useForm } from "@mantine/form"
import { InvStore } from 'src/inventory-app/models/InvStore'

export function EditItemModal({ opened, onClose, options }: {
  opened: boolean,
  onClose: () => void,
  options: {
    title: string
    item: InvStore.Item
    validateCode: (code: string, owner: InvStore.Item) => string | null
    onSave: (_: InvStore.Item) => void
  }
}) {
  const { title, item, validateCode, onSave } = options

  const form = useForm({
    mode: 'controlled',
    initialValues: {
      name: item.name,
      code: item.code,
    },
    validate: {
      name: isNotEmpty('Name is required'),
      code: (code1) => {
        const code = code1.trim()

        if (!code) {
          return 'Code is required'
        }

        return validateCode(code, item)
      }
    }
  })

  function handleSubmit(values: typeof form.values) {
    onClose()
    
    onSave({
      ...item,
      name: values.name.trim(),
      code: values.code.trim()
    })
  }

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={title}
      returnFocus={false}
    >
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack>
          <TextInput
            data-autofocus
            label='Name'
            key={form.key('name')}
            {...form.getInputProps('name')}
          />
          <TextInput
            label='Code'
            key={form.key('code')}
            {...form.getInputProps('code')}
          />
          <Button type='submit' ml='auto'>Save</Button>
        </Stack>
      </form>
    </Modal>
  )
}