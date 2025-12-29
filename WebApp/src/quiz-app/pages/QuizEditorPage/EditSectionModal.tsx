import { Button, Group, Modal, Stack, TextInput } from "@mantine/core"
import { isNotEmpty, useForm } from "@mantine/form"
import { Quiz } from 'src/quiz-app/models/Quiz'

export function EditSectionModal({ opened, onClose, options }: {
  opened: boolean,
  onClose: () => void,
  options: {
    title: string
    section: Quiz.Section,
    onSave: (_: Quiz.Section) => void
  }
}) {
  const { title, section, onSave } = options

  const form = useForm({
    mode: 'controlled',
    initialValues: {
      name: section.name
    },
    validate: {
      name: isNotEmpty('Required')
    }
  })

  function handleSubmit(values: typeof form.values) {
    onClose()
    onSave({
      ...section,
      name: values.name
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