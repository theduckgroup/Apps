import React from 'react'
import { useMutation } from '@tanstack/react-query'
import { Modal, Text, Button, Group, Stack, PasswordInput } from '@mantine/core'
import { hasLength, isNotEmpty, useForm } from '@mantine/form'

import { User } from 'src/app/models/User'
import sleep from 'src/common/sleep'
import axios from 'axios'
import formatError from 'src/common/format-error'

const SetPasswordModal: React.FC<SetPasswordModalProps> = ({ user, opened, onClose }) => {
  const form = useForm({
    initialValues: {
      password: ''
    },
    validate: {
      password: (
        isNotEmpty('Required') &&
        hasLength({ min: 8 }, 'Password must be at least 8 characters')
      )
    }
  })

  const mutation = useMutation<void, Error, typeof form.values>({
    mutationFn: async (data) => {
      await sleep(500)
      return (await axios.patch(`/api/users/${user.id}/set_password`, data)).data
    },
    onSuccess: () => {
      onClose()
    }
  })

  const handleSubmit = (values: typeof form.values) => {
    mutation.mutate(values)
  }

  return (
    <Modal
      title='Set Password'
      opened={opened}
      onClose={onClose}
    >
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack gap='md'>
          <PasswordInput
            label='New Password'
            data-autofocus
            required
            autoComplete='new-password'
            {...form.getInputProps('password')}
          />
          {mutation.error && <Text c='red'>{formatError(mutation.error)}</Text>}
          <Group justify='flex-end' mt='md'>
            <Button variant='default' miw='6rem' onClick={onClose}>
              Cancel
            </Button>
            <Button type='submit' miw='6rem' loading={mutation.isPending} disabled={mutation.isPending}>Save</Button>
          </Group>
        </Stack>
      </form>
    </Modal>
  )
}

export default SetPasswordModal

interface SetPasswordModalProps {
  user: User
  opened: boolean
  onClose: () => void
}