import { useEffect, useRef } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Navigate } from 'react-router'
import { Text, TextInput, Button, Stack, Box, PasswordInput, Title } from '@mantine/core'
import { useForm, isNotEmpty } from '@mantine/form'

import { useAuth } from './AuthContext'

const LoginPage = () => {
  const auth = useAuth()
  
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

  if (auth.user) {
    return <Navigate to='/' />
  }

  return (
    <div className='w-screen h-screen flex'>
      <Stack align='center' m='auto'>
        <Title order={2} mb={0}>Quiz</Title>
        <Box mih='24px'>
          {(error && !isPending) && <Text c='red' ta='center' fz='sm'>{error.message}</Text>}
        </Box>
        <form onSubmit={form.onSubmit(handleSubmit)}>
          <Stack w='250' gap='sm'>
            <TextInput
              ref={emailRef}
              label='Email'
              placeholder=''
              key={form.key('email')}
              {...form.getInputProps('email')}
            />
            <PasswordInput
              label='Password'
              placeholder=''
              key={form.key('password')}
              {...form.getInputProps('password')}
            />
            <Button
              type='submit'
              variant='filled'
              fullWidth
              loading={form.submitting}
            >
              <Text>Log in</Text>
            </Button>
          </Stack>
        </form>
        {/* To align vertically */}
        <Box h='90px'/>
      </Stack>
    </div>
  )
}

export default LoginPage