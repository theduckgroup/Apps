import { Text, Modal, Button, TextInput, PasswordInput, Group, Stack, Grid, Select, Box, List, Paper } from '@mantine/core'
import { useRef, useEffect } from 'react'
import { hasLength, isEmail, isNotEmpty, useForm } from '@mantine/form'
import { useMutation } from '@tanstack/react-query'

import { useAuth, useApi } from 'src/app/contexts'
import formatError from 'src/common/format-error'
import sleep from 'src/common/sleep'
import RoleSelect from './RoleSelect'

export default function AddUserModal({ opened, onClose }: AddUserModalProps) {
  const { user: currentUser } = useAuth()
  const { axios } = useApi()
  const isOwner = currentUser?.isOwner ?? false

  const emailRef = useRef<HTMLInputElement>(null)

  const form = useForm<FormValues>({
    initialValues: {
      email: '',
      firstName: '',
      lastName: '',
      password: '',
      role: 'user',
    },
    validate: {
      email: isEmail('Invalid email'),
      password: isNotEmpty('Required') && hasLength({ min: 8 }, 'Password must be at least 8 characters'),
      // firstName: isNotEmpty('Required'),
      // lastName: isNotEmpty('Required'),
    },
  })

  const mutation = useMutation<void, Error, FormValues>({
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

      return (await axios.post('/user', body)).data
    },
    onSuccess: () => {
      form.reset()
      onClose()
    }
  })

  const handleSubmit = (values: FormValues) => {
    mutation.mutate(form.values)
  }

  const handleClose = () => {
    // form.isDirty()

    onClose()
    form.reset()
  }

  useEffect(() => {
    setTimeout(() => {
      if (opened && emailRef.current) {
        emailRef.current.focus()
      }
    }, 50)
  }, [opened])

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
            <TextInput
              label='Email'
              type='email'
              required
              autoComplete='off'
              {...form.getInputProps('email')}
              ref={emailRef}
            />

            <PasswordInput
              label='Password'
              autoComplete='off'
              required
              {...form.getInputProps('password')}
            />

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
              isOwner={isOwner}
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

interface AddUserModalProps {
  opened: boolean
  onClose: () => void
}

interface FormValues {
  firstName: string
  lastName: string
  email: string
  password: string
  role: 'owner' | 'admin' | 'user'
}