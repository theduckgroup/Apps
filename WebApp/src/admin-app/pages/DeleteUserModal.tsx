import { useMutation } from '@tanstack/react-query'
import { Button, Group, Modal, Text } from '@mantine/core'
import axios from 'axios'
import formatError from 'src/common/format-error'
import sleep from 'src/common/sleep'

export default function DeleteUserModal({ userId, opened, onClose }: DeleteUserModalProps) {
  const { mutate: deleteUser, isPending: isDeleting, error: deleteError } = useMutation({
    mutationFn: async (userId: string) => {
      // Can't use wait({ minMs }) -- UI will refresh immediately after user is delete
      await sleep(500)
      await axios.delete(`/api/users/${userId}`)
    },
    onSuccess: () => {
      onClose()
    }
  })

  const handleDelete = () => {
    deleteUser(userId)
  }

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title='Confirm Delete'
    >
      <Text size='sm'>Are you sure you want to delete this user?</Text>
      {deleteError && <Text size="sm" c="red">{formatError(deleteError)}</Text>}
      <Group justify='flex-end' mt='md'>
        <Button variant='default' onClick={onClose}>
          Cancel
        </Button>
        <Button
          color='red'
          onClick={handleDelete}
          loading={isDeleting}
          disabled={isDeleting}
        >
          Delete
        </Button>
      </Group>
    </Modal>
  )
}

interface DeleteUserModalProps {
  userId: string
  opened: boolean
  onClose: () => void
}
