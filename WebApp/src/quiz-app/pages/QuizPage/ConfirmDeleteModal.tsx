import { Button, Group, Modal, Stack } from "@mantine/core"
import { ReactNode } from "react"

export default function ConfirmDeleteModal({ opened, close, options }: {
  opened: boolean,
  close: () => void,
  options: ConfirmDeleteModalOptions
}) {
  return (
    <Modal
      opened={opened}
      onClose={close}
      withCloseButton={false}
      returnFocus={false}
    >
      <Stack>
        <Group>{options.message}</Group>
        <Group ml='auto'>
          <Button
            variant='default'
            onClick={() => close()}
          >
            Cancel
          </Button>
          <Button color='red' onClick={() => {
            close()
            options.onDelete()
          }}>
            Delete
          </Button>
        </Group>
      </Stack>
    </Modal>
  )
}

export interface ConfirmDeleteModalOptions {
  message: ReactNode
  onDelete: () => void
}

export namespace ConfirmDeleteModalOptions {
  export const empty: ConfirmDeleteModalOptions = {
    message: '',
    onDelete: () => { }
  }
}