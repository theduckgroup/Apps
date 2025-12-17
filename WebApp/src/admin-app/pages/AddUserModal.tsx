import { Text, Modal, Button, TextInput, PasswordInput, Group, Stack, Grid } from '@mantine/core'
import { hasLength, isEmail, isNotEmpty, useForm } from '@mantine/form'
import { useMutation } from '@tanstack/react-query'

import { useApi } from 'src/app/contexts'
import formatError from 'src/common/format-error'
import sleep from 'src/common/sleep'
import RoleSelect from './RoleSelect'

export function AddUserModal({ opened, onClose }: {
  opened: boolean
  onClose: () => void
}) {
  const { axios } = useApi()

  type Role = 'owner' | 'admin' | 'user'

  const form = useForm({
    initialValues: {
      email: '',
      firstName: '',
      lastName: '',
      password: '',
      passwordConfirm: '',
      role: 'user' as Role,
    },
    validate: {
      email: isEmail('Invalid email'),
      password: isNotEmpty('Required') && hasLength({ min: 8 }, 'Password must be at least 8 characters'),
      passwordConfirm: (value, values) => {
        return value != values.password ? 'Password does not match' : null
      }
    },
  })

  const mutation = useMutation<void, Error, typeof form.values>({
    mutationFn: async (data) => {
      await sleep(500)

      const body = {
        email: data.email,
        password: data.password,
        user_metadata: {
          first_name: data.firstName,
          last_name: data.lastName,
        },
        app_metadata: {
          roles: (() => {
            switch (data.role) {
              case 'owner': return ['org:owner']
              case 'admin': return ['org:admin']
              case 'user': return []
            }
          })()
        }
      }

      return (await axios.post('/users', body)).data
    },
    onSuccess: () => {
      form.reset()
      onClose()
    }
  })

  const handleSubmit = (values: typeof form.values) => {
    mutation.mutate(form.values)
  }

  const handleClose = () => {
    // form.isDirty()

    onClose()
    form.reset()
  }

  return (
    <>
      <Modal
        title='Add User'
        opened={opened}
        onClose={handleClose}
        closeOnClickOutside={false}
      >
        <form onSubmit={form.onSubmit(handleSubmit)}>
          <Stack gap='md'>
            {/* Email */}
            <TextInput
              label='Email'
              type='email'
              required
              data-autofocus
              autoComplete='off'
              {...form.getInputProps('email')}
            />

            {/* Password */}
            <PasswordInput
              label='Password'
              autoComplete='off'
              required
              {...form.getInputProps('password')}
            />

            <PasswordInput
              label='Confirm Password'
              required
              autoComplete='off'
              {...form.getInputProps('passwordConfirm')}
            />

            {/* First & Last Name */}
            <Grid>
              <Grid.Col span={6}>
                <TextInput
                  label='First Name'
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

            {/* Role select */}
            <RoleSelect
              role={form.values.role}
              selectInputProps={form.getInputProps('role')}
            />

            {/* Error */}
            {mutation.error &&
              <Text c='red' size='sm' mb=''>
                Error: {formatError(mutation.error)}
              </Text>
            }

            {/* Buttons Group - justify='flex-end' aligns children to the right */}
            <Group justify='flex-end' mt='md'>
              <Button variant='default' w='6rem' onClick={handleClose}>Cancel</Button>
              <Button type='submit' w='6rem' loading={mutation.isPending}>Save</Button>
            </Group>
          </Stack>
        </form>
      </Modal>
    </>
  )
}