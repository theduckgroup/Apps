import { Button, Group, Modal, Stack, TextInput } from "@mantine/core"
import { isNotEmpty, useForm } from "@mantine/form"
import { useEffect, useRef } from "react"
import { Quiz } from 'src/quiz-app/models/Quiz'

export default function EditSectionModal({ opened, close, options }: {
  opened: boolean,
  close: () => void,
  options: EditSectionModalOptions | null
}) {
  if (options) {
    return <Content opened={opened} close={close} options={options} />
  } else {
    return null
  }
}

function Content({ opened, close, options }: {
  opened: boolean,
  close: () => void,
  options: EditSectionModalOptions
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
    close()
    options.onSave({
      ...options.section,
      name: values.name
    })
  }

  return (
    <Modal
      opened={opened}
      onClose={close}
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
            <Button variant='default' onClick={close} w='6rem'>Cancel</Button>
            <Button type='submit' w='6rem'>Save</Button>
          </Group>
        </Stack>
      </form>
    </Modal>
  )
}

export interface EditSectionModalOptions {
  title: string
  section: Quiz.Section,
  onSave: (modifiedSection: Quiz.Section) => void
}