import { Box, Button, FocusTrap, Group, Modal, Text } from '@mantine/core'

import formatError from 'src/common/format-error'
import { useState } from 'react'

export function ConfirmModal({ opened, onClose, options }: {
  opened: boolean
  onClose: () => void
  options: ConfirmModal.Options
}) {
  const { title, message } = options
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<Error | undefined>()
  const actions = 'action' in options ? [options.action] : options.actions

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
  export type Options = {
    title: string
    message: React.ReactNode    
  } & (
    | {
      actions: Action[]
    }
    | {
      action: Action
    }
  )

  export type Action = {
    label: React.ReactNode
    role?: 'confirm' | 'destructive'
    handler: () => void | Promise<void>
  }
}