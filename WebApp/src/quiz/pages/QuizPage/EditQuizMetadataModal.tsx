import { Button, Group, Modal, NumberInput, Stack, TextInput } from "@mantine/core"
import { isInRange, isNotEmpty, useForm } from "@mantine/form"
import { useEffect, useRef } from "react"

export function EditQuizMetadataModal(
  props: Omit<EditQuizMetadataModal.Props, 'options'> & { options: EditQuizMetadataModal.Options | undefined }
) {
  if (props.options) {
    return EditQuizMetadataModalImpl({ ...props, options: props.options })
  } else {
    return null
  }
}

function EditQuizMetadataModalImpl({ opened, close, options }: EditQuizMetadataModal.Props) {
  const form = useForm({
    mode: 'controlled',
    initialValues: {
      name: options.data.name,
      code: options.data.code,
      itemsPerPage: options.data.itemsPerPage
    },
    validate: {
      name: isNotEmpty('Required'),
      itemsPerPage: (value) => isNotEmpty('Required')(value) || isInRange({ min: 5, max: 100 }, 'Out of range')(value)
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

  function handleSave(values: typeof form.values) {
    close()
    options.onSave({
      name: values.name.trim(),
      code: values.code.trim(),
      itemsPerPage: values.itemsPerPage
    })
  }

  return (
    <Modal
      opened={opened}
      onClose={close}
      title='Edit Quiz'
      returnFocus={false}
      closeOnClickOutside={false}
    >
      <form onSubmit={form.onSubmit(handleSave)}>
        <Stack>
          <TextInput
            ref={nameRef}
            label='Name'
            key={form.key('name')}
            {...form.getInputProps('name')}
          />
          <TextInput
            label='Code'
            key={form.key('code')}
            {...form.getInputProps('code')}
          />
          <NumberInput
            label="Items per Page"
            min={5}
            max={100}
            clampBehavior='none'
            key={form.key('itemsPerPage')}
            {...form.getInputProps('itemsPerPage')}
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

export namespace EditQuizMetadataModal {
  export interface Props {
    opened: boolean,
    close: () => void,
    options: Options
  }

  export interface Options {
    data: Data
    onSave: (_: Data) => void
  }

  interface Data {
    name: string
    code: string
    itemsPerPage: number
  }
}

