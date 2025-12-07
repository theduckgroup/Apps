import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router'
import { useMutation } from '@tanstack/react-query'
import { Text, TextInput, Button, Stack, Box, Title, Anchor } from '@mantine/core'
import { useForm, isNotEmpty, isEmail } from '@mantine/form'

import { useAuth } from '../contexts'
import formatError from 'src/common/format-error'

function ResetPasswordPage() {
  const auth = useAuth()
  const navigate = useNavigate()

  const form = useForm({
    mode: 'controlled',
    initialValues: {
      email: ''
    },
    validate: {
      email: isNotEmpty('Required') && isEmail('Invalid email')
    }
  })

  const { mutateAsync: submit, error, isPending } = useMutation<void, Error, typeof form.values>({
    mutationFn: async (values: typeof form.values) => {
      return await auth.resetPassword(values.email)
    }
  })

  async function handleSubmit(values: typeof form.values) {
    await submit(values)
    setDidSubmit(true)
  }

  const [didSubmit, setDidSubmit] = useState(false)

  const emailRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (emailRef.current) {
      emailRef.current.focus()
    }
  }, [])

  return (
    <div className='w-screen h-screen flex'>
      <title>Reset Password | The Duck Group</title>

      <Stack align='center' m='auto'>
        {/* Title */}
        <Title order={4} mb='lg'>Reset Password</Title>

        {
          !didSubmit ?
            // Form
            <form onSubmit={form.onSubmit(handleSubmit)}>
              <Stack w='15rem' gap='sm'>
                {/* Email */}
                <TextInput
                  ref={emailRef}
                  label='Email'
                  placeholder=''
                  data-autofocus
                  key={form.key('email')}
                  {...form.getInputProps('email')}
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
            <Text w='24rem' fz='sm' ta='center'>An email has been sent to {form.values.email}<br/>Follow the instructions to reset your password</Text>
        }

        {/* Back to Login */}
        <Stack w='100%' align='center'>
          <Anchor
            fz='sm'
            onClick={e => {
              e.preventDefault()
              navigate('/login')
            }}
          >
            Back to Login
          </Anchor>
        </Stack>
      </Stack>
    </div >
  )
}

export default ResetPasswordPage