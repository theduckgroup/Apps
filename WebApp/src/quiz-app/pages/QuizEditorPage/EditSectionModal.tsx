import { Button, Group, Modal, Stack, TextInput } from "@mantine/core"
import { isNotEmpty, useForm } from "@mantine/form"
import { useEffect, useRef } from "react"
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
  const form = useForm({
    mode: 'controlled',
    initialValues: {
      name: options.section.name
    },
    validate: {
      name: isNotEmpty('Required')
    }
  })

  const nameRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    nameRef.current?.focus()
  }, [])

  useEffect(() => {
    if (opened) {
      // Need to wait for nameRef to be set
      setTimeout(() => {
        nameRef.current?.focus()
      }, 50)
    }
  }, [opened])

  function handleSubmit(values: typeof form.values) {
    onClose()
    options.onSave({
      ...options.section,
      name: values.name
    })
  }

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={options?.title}
      returnFocus={false}
      closeOnClickOutside={false}
    >
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack>
          <TextInput
            ref={nameRef}
            label='Name'
            key={form.key('name')}
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