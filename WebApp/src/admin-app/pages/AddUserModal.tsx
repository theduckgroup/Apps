import { Text, Modal, Button, TextInput, PasswordInput, Group, Stack, Grid, Select, Box, List, Paper } from '@mantine/core'
import { useRef, useEffect, useState } from 'react'
import { hasLength, isEmail, isNotEmpty, useForm } from '@mantine/form'
import { useMutation } from '@tanstack/react-query'
import { IconInfoCircle } from '@tabler/icons-react'

import { useAuth } from 'src/app/providers/AuthContext'
import { useApi } from 'src/app/providers/ApiContext'
import formatError from 'src/common/format-error'
import sleep from 'src/common/sleep'

export default function AddUserModal({ opened, onClose }: AddUserModalProps) {
  const { user: currentUser } = useAuth()
  const { axios } = useApi()
  const isOwner = currentUser && currentUser.isOwner

  const emailRef = useRef<HTMLInputElement>(null)
  const [roleInfoVisible, setRoleInfoVisible] = useState(false)

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
      setRoleInfoVisible(false)
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
      >
        <form onSubmit={form.onSubmit(handleSubmit)}>
          <Stack gap='md'>
            <TextInput
              label='Email'
              type='email'
              required
              {...form.getInputProps('email')}
              ref={emailRef}

            />

            <PasswordInput
              label='Password'
              autoComplete='new-password'
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

            <Stack align='flex-start' w='100%' gap='0.05rem'>
              <Text fz='sm'>Role</Text>
              <Group align='center' gap='sm' wrap='nowrap'>
                <Select
                  placeholder='Select a role'
                  data={[
                    { value: 'owner', label: 'Owner' },
                    { value: 'admin', label: 'Admin' },
                    { value: 'user', label: 'User' }
                  ]}
                  required
                  {...form.getInputProps('role')}
                  w='60%' // ??
                  disabled={!isOwner}
                />
                <Button
                  variant='transparent' p={0}
                  onClick={() => {
                    setRoleInfoVisible(!roleInfoVisible)
                  }}
                >
                  <IconInfoCircle size={17} stroke={2} />
                </Button>
              </Group>
            </Stack>

            {/* Role Warnings */}
            {
              form.values.role == 'owner' &&
              <Paper bg='red.8' px='md' py='xs' radius='sm'>
                <Text c='white'>Owner can create/update/delete other owners (including yourself!)</Text>
              </Paper>
            }
            {
              form.values.role == 'admin' &&
              <Paper bg='blue.8' px='md' py='xs' radius='sm'>
                <Text c='white'>Admin can create/update/delete users but cannot modify owners or other admins</Text>
              </Paper>
            }

            {/* Roles Info */}
            {roleInfoVisible &&
              <Paper bg='dark.6' px='md' py='xs' radius='sm'>
                <Stack gap='0'>
                  <Text>Owner can create/update/delete owners, admins and users.</Text>
                  <Text>Admin can create/update/delete users.</Text>
                  <Text>User can't see other users.</Text>
                </Stack>
              </Paper>
            }

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