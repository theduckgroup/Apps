import { Button, Modal, Stack, TextInput } from "@mantine/core"
import { isNotEmpty, useForm } from "@mantine/form"
import { useEffect, useRef } from "react"

export default function EditSectionModal({ opened, close, options }: {
  opened: boolean,
  close: () => void,
  options: EditSectionModalOptions
}) {
  const form = useForm({
    mode: 'controlled',
    initialValues: {
      name: ''
    },
    validate: {
      name: isNotEmpty('Name is required')
    }
  })

  const nameRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    if (options) {
      form.setValues({
        name: options.fields.name
      })

      nameRef.current?.focus()
    }

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [options])

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
      name: values.name.trim()
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
          <Button type='submit' ml='auto'>Save</Button>
        </Stack>
      </form>
    </Modal>
  )
}

export interface EditSectionModalOptions {
  title: string
  fields: {
    name: string
  }
  onSave: (fields: { name: string }) => void
}

export namespace EditSectionModalOptions {
  export const empty: EditSectionModalOptions = {
    title: '',
    fields: { name: '' },
    onSave: () => { }
  }
}
