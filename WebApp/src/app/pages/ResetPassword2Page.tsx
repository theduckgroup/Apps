import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router'
import { useMutation } from '@tanstack/react-query'
import { Text, Button, Stack, Box, Title, Anchor, PasswordInput } from '@mantine/core'
import { useForm, isNotEmpty, hasLength } from '@mantine/form'

import { useAuth } from '../contexts'
import formatError from 'src/common/format-error'
import axios from 'axios'

function ResetPasswordPage2() {
  const { getSession, user, logout } = useAuth()
  const navigate = useNavigate()

  const form = useForm({
    mode: 'controlled',
    initialValues: {
      password: '',
      confirmPassword: ''
    },
    validate: {
      password: (
        isNotEmpty('Required') &&
        hasLength({ min: 8 }, 'Password must be at least 8 characters')
      ),
      confirmPassword: (value, values) => {
        return value != values.password ? 'Password does not match' : null
      }
    }
  })

  const { mutateAsync: submit, error, isPending } = useMutation<void, Error, typeof form.values>({
    mutationFn: async (values: typeof form.values) => {
      // Same logic as ApiProvider

      const session = await getSession()

      if (!session) {
        throw new Error('Not Authorized')
      }

      const data = {
        password: values.password
      }

      await axios.patch(`/api/admin/user/${user!.id}`, data, {
        headers: {
          'Authorization': `Bearer ${session.access_token}`
        }
      })
    }
  })

  async function handleSubmit(values: typeof form.values) {
    await submit(values)
    setDidSubmit(true)
  }

  const [didSubmit, setDidSubmit] = useState(false)

  const passwordRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (passwordRef.current) {
      passwordRef.current.focus()
    }
  }, [])

  return (
    <div className='w-screen h-screen flex'>
      <Stack align='center' m='auto'>
        {/* Title */}
        <Title order={4} mb='lg'>Reset Password</Title>

        {
          !didSubmit ?
            // Form
            <form onSubmit={form.onSubmit(handleSubmit)}>
              <Stack w='15rem' gap='sm'>
                {/* Password */}
                <PasswordInput
                  ref={passwordRef}
                  label='New Password'
                  placeholder=''
                  key={form.key('password')}
                  {...form.getInputProps('password')}
                />

                {/* Confirm Password */}
                <PasswordInput
                  label='Confirm New Password'
                  placeholder=''
                  key={form.key('confirmPassword')}
                  {...form.getInputProps('confirmPassword')}
                />

                {/* Submit button */}
                <Button
                  type='submit'
                  variant='filled'
                  fullWidth
                  loading={form.submitting}
                >
                  <Text>Submit</Text>
                </Button>

                {/* Error */}
                <Box mih='24px'>
                  {(error && !isPending) && <Text c='red' ta='center' fz='sm'>{formatError(error)}</Text>}
                </Box>
              </Stack>
            </form> :
            // Submitted message
            <Stack>
              <Text w='24rem' fz='sm' ta='center'>Password has been updated.</Text>
              
              {/* Back to Login */}
              <Stack w='100%' align='center'>
                <Anchor
                  fz='sm'
                  onClick={async e => {
                    e.preventDefault()
                    await logout()
                    navigate('/login')
                  }}
                >
                  Back to Login
                </Anchor>
              </Stack>
            </Stack>
        }
      </Stack>
    </div >
  )
}

export default ResetPasswordPage2