import { useEffect, useRef } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Text, TextInput, Button, Stack, Box, PasswordInput, Title, Anchor } from '@mantine/core'
import { useForm, isNotEmpty } from '@mantine/form'

import { useAuth } from '../contexts'
import formatError from 'src/common/format-error'
import { useNavigate } from 'react-router'

const LoginPage = () => {
  const auth = useAuth()
  const navigate = useNavigate()

  const form = useForm({
    mode: 'controlled',
    validateInputOnChange: true,
    initialValues: {
      email: '',
      password: ''
    },
    validate: {
      email: isNotEmpty('Required'),
      password: isNotEmpty('Required')
    }
  })

  const emailRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (emailRef.current) {
      emailRef.current.focus()
    }
  }, [])

  const { mutateAsync: login, error, isPending } = useMutation<void, Error, typeof form.values>({
    mutationFn: async (values: typeof form.values) => {
      await auth.login(values)
    }
  })

  async function handleSubmit(values: typeof form.values) {
    await login(values)
  }

  // if (auth.user) {
  //   return <Navigate to='/' />
  // }

  return (
    <div className='w-screen h-screen flex'>
      <title>Login | The Duck Group</title>

      <Stack align='center' m='auto'>
        {/* Title */}
        <Title order={2} mb='lg'>The Duck Group</Title>

        {/* Form */}
        <form onSubmit={form.onSubmit(handleSubmit)}>
          <Stack w='270' gap='sm'>
            {/* Email */}
            <TextInput
              ref={emailRef}
              label='Email'
              placeholder=''
              autoCapitalize='none'
              key={form.key('email')}
              {...form.getInputProps('email')}
            />
            {/* Password */}
            <PasswordInput
              label='Password'
              placeholder=''
              key={form.key('password')}
              {...form.getInputProps('password')}
            />
            {/* Login button */}
            <Button
              type='submit'
              variant='filled'
              fullWidth
              loading={form.submitting}
            >
              <Text>Log in</Text>
            </Button>
            {/* Reset Password */}
            <Stack w='100%' align='center'>
              <Anchor
                fz='sm'
                onClick={e => {
                  e.preventDefault()
                  navigate('/reset-password')
                }}
              >
                Reset Password
              </Anchor>
            </Stack>
          </Stack>

        </form>

        {/* Error */}
        <Box mih='24px'>
          {(error && !isPending) && <Text c='red' ta='center' fz='sm'>{formatError(error)}</Text>}
        </Box>
      </Stack >
    </div >
  )
}

export default LoginPage