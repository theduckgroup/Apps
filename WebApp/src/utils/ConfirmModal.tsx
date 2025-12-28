import { Button, FocusTrap, Group, Modal, Stack, Text } from '@mantine/core'

import formatError from 'src/common/format-error'
import { useState } from 'react'

export function ConfirmModal({ opened, onClose, options: { title, message, actions } }: {
  opened: boolean
  onClose: () => void
  options: ConfirmModal.Options
}) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<Error | undefined>()

  async function handleActionClick(action: ConfirmModal.Action) {
    try {
      setError(undefined)

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
      <Stack gap='md'>
        <FocusTrap.InitialFocus />

        <Stack fz='sm' gap='xs'>
          {message}
          {error && <Text size="sm" c="red"> {formatError(error)} </Text>}
        </Stack>

        <Group justify='flex-end'>
          <Button variant='default' onClick={onClose}>
            Cancel
          </Button>
          {actions.map(action => {
            return (
              <Button
                variant='filled'
                color={(action.role ?? 'confirm') == 'confirm' ? undefined : 'red'}
                onClick={() => handleActionClick(action)}
                loading={loading}
                disabled={loading}
              >
                {action.label}
              </Button>
            )
          })}
        </Group>
      </Stack>
    </Modal>
  )
}

export namespace ConfirmModal {
  export type Options = {
    title?: React.ReactNode
    message?: React.ReactNode
    actions: Action[]
  }

  export type Action = {
    label: React.ReactNode
    role?: 'confirm' | 'destructive'
    handler: () => void | Promise<void>
  }
}