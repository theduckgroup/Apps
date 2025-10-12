import React from 'react'
import { useMutation } from '@tanstack/react-query'
import { Modal, Text, TextInput, Button, Group, Grid, Stack } from '@mantine/core'
import { useForm } from '@mantine/form'

import { useApi, useAuth } from 'src/app/contexts'
import { User } from 'src/app/models/User'
import sleep from 'src/common/sleep'
import formatError from 'src/common/format-error'
import RoleSelect from './RoleSelect'

const EditUserModal: React.FC<EditUserModalProps> = ({ title, user, opened, onClose }) => {
  const { axios } = useApi()
  const { user: currentUser } = useAuth()
  const isOwner = currentUser?.isOwner ?? false
  const isEditingSelf = currentUser?.id == user.id

  const role: 'owner' | 'admin' | 'user' = (
    user.appMetadata.roles.includes('org:owner') ? 'owner' :
      user.appMetadata.roles.includes('org:admin') ? 'admin' :
        'user'
  )

  const form = useForm({
    initialValues: {
      firstName: user.userMetadata.firstName,
      lastName: user.userMetadata.lastName,
      role: role
    },
    validate: {
      // firstName: isNotEmpty('Required'),
      // lastName: isNotEmpty('Required'),
    },
  })

  const mutation = useMutation<void, Error, typeof form.values>({
    mutationFn: async (data) => {
      await sleep(500)

      const body = {
        user_metadata: {
          first_name: data.firstName,
          last_name: data.lastName,
        },
        app_metadata: {
          roles: (
            data.role == 'owner' ? ['org:owner'] :
              data.role == 'admin' ? ['org:admin'] :
                []
          )
        }
      }

      return (await axios.patch(`/user/${user.id}`, body)).data
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
      title={title}
      opened={opened}
      onClose={onClose}
      closeOnClickOutside={false}
    >
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack gap='md'>
          {/* First & Last name */}
          <Grid>
            <Grid.Col span={6}>
              <TextInput
                label='First Name'
                data-autofocus
                {...form.getInputProps('firstName')}
              />
            </Grid.Col>
            <Grid.Col span={6}>
              <TextInput
                label='Last Name'
                {...form.getInputProps('lastName')}
              />
            </Grid.Col>
          </Grid>


          {/* Role */}
          {
            isOwner &&
            <RoleSelect
              role={form.values.role}
              disabled={isEditingSelf}
              selectInputProps={form.getInputProps('role')}
            />
          }

          {/* Error */}
          {mutation.error && <Text c='red'>{formatError(mutation.error)}</Text>}

          {/* Save/Cancel buttons */}
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

export default EditUserModal

interface EditUserModalProps {
  title: string
  user: User
  opened: boolean
  onClose: () => void
}