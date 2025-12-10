import { Button, Group, Modal, Stack, Textarea, TextInput, Text } from "@mantine/core"
import { isNotEmpty, useForm } from "@mantine/form"
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
      emailRecipients: options.data.emailRecipients.join('\n')
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

  function handleSave(values: typeof form.values) {
    const emailRecipients = values.emailRecipients
      .split(/[,;\n]+/) // split by comma, semicolon, or newline (one or more)
      .map(part => part.trim()) // remove surrounding whitespace
      .filter(Boolean) // remove empty strings

    close()
    options.onSave({
      name: values.name.trim(),
      code: values.code.trim(),
      emailRecipients
    })
  }

  return (
    <Modal
      opened={opened}
      onClose={close}
      title='Edit Test'
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
          {/* <NumberInput
            label="Items per Page"
            min={5}
            max={100}
            clampBehavior='none'
            key={form.key('itemsPerPage')}
            {...form.getInputProps('itemsPerPage')}
          /> */}
          <Stack gap='0.25rem'>
            <Textarea
              label='Email Recipients'
              autosize
              key={form.key('emailRecipients')}
              {...form.getInputProps('emailRecipients')}
            />
            <Text fz='sm' c='dark.2'>* Separated by newlines, comma or semicolon</Text>
          </Stack>
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
    emailRecipients: string[]
  }
}

