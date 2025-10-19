import { Box, Button, FocusTrap, Group, Modal, Text } from '@mantine/core'

import formatError from 'src/common/format-error'
import { useState } from 'react'

export function ConfirmModal({
  options: { title, message, actions },
  opened, onClose
}: ConfirmModal.Props) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<Error | undefined>()

  async function handleActionClick(action: ConfirmModal.Action) {
    try {
      const result = action.handler()

      if (result instanceof Promise) {
        setLoading(true)
        await result
      }

      onClose()
      
    } catch (e) {
      setError(e as Error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      withCloseButton={false}
      title={title}
    >
      <FocusTrap.InitialFocus />

      <Box fz='sm'>
        {message}
      </Box>

      {error && <Text size="sm" c="red"> {formatError(error)} </Text>}

      <Group justify='flex-end' mt='md' >
        <Button variant='default' onClick={onClose} >
          Cancel
        </Button>
        {actions.map(action => {
          const handleClick = async () => {

          }

          return (
            <Button
              variant='filled'
              color={action.role == 'confirm' ? undefined : 'red'}
              onClick={() => handleActionClick(action)}
              loading={loading}
              disabled={loading}
            >
              {action.label}
            </Button>
          )
        })}
      </Group>
    </Modal>
  )
}

export namespace ConfirmModal {
  export interface Props {
    opened: boolean
    onClose: () => void
    options: Options
  }

  export interface Options {
    title: string
    message: React.ReactNode
    actions: Action[]
  }

  export interface Action {
    label: React.ReactNode
    role?: 'confirm' | 'destructive'
    handler: () => void | Promise<void>
  }
}