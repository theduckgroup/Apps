import React from 'react'
import { useMutation } from '@tanstack/react-query'
import { Modal, Text, Button, Group, Stack, PasswordInput } from '@mantine/core'
import { hasLength, isNotEmpty, useForm } from '@mantine/form'

import { useApi, useAuth } from 'src/app/contexts'
import { User } from 'src/app/models/User'
import formatError from 'src/common/format-error'

const SetPasswordModal: React.FC<SetPasswordModalProps> = ({ user, opened, onClose }) => {
  const { user: currentUser } = useAuth()
  const { axios } = useApi()
  const userIsCurrentUser = currentUser?.id == user.id

  const form = useForm({
    initialValues: {
      password: '',
      passwordConfirm: '',
    },
    validate: {
      password: (
        isNotEmpty('Required') &&
        hasLength({ min: 8 }, 'Password must be at least 8 characters')
      ),
      passwordConfirm: (value, values) => {
        return value != values.password ? 'Password does not match' : null
      }
    }
  })

  const mutation = useMutation<void, Error, typeof form.values>({
    mutationFn: async (values) => {
      const data = {
        password: values.password
      }

      return (await axios.patch(`/user/${user.id}`, data)).data
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
      closeOnClickOutside={false}
    >
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack gap='xs'>
          {/* Password & Confirm password */}
          <Stack gap='md'>
            <PasswordInput
              label='New Password'
              data-autofocus
              required
              autoComplete='new-password'
              {...form.getInputProps('password')}
            />

            <PasswordInput
              label='Confirm New Password'
              data-autofocus
              required
              autoComplete='off'
              {...form.getInputProps('passwordConfirm')}
            />
          </Stack>

          <Text c='yellow' fz='sm'>
            {userIsCurrentUser ? 'You' : 'User'} will be logged out after changing password
          </Text>

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