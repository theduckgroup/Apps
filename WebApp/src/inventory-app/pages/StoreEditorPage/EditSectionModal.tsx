import { Button, Modal, Stack, TextInput } from "@mantine/core"
import { isNotEmpty, useForm } from "@mantine/form"
import { useEffect, useRef } from "react"
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
        name: options.section.name
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
      ...options.section,
      name: values.name.trim()
    })
  }

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={options?.title}
      returnFocus={false}
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
