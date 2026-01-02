import { useState } from 'react'
import { Button, ButtonVariant, DefaultMantineColor, FocusTrap, Group, Modal, Stack, Text } from '@mantine/core'
import formatError from 'src/common/format-error'

export function ConfirmModal({ opened, onClose, options: { title, message, actions } }: {
  opened: boolean
  onClose: () => void
  options: ConfirmModal.Options
}) {
  const [loadingAction, setLoadingAction] = useState<ConfirmModal.Action | undefined>()
  const [error, setError] = useState<Error | undefined>()

  if (!actions.find(x => x.role == 'cancel')) {
    const cancelAction: ConfirmModal.Action = {
      label: 'Cancel',
      role: 'cancel',
      handler: onClose
    }
    
    actions = [cancelAction, ...actions]
  }

  async function handleActionClick(action: ConfirmModal.Action) {
    try {
      setError(undefined)

      const result = action.handler()

      if (result instanceof Promise) {
        setLoadingAction(action)
        await result
      }

      onClose()

    } catch (e) {
      setError(e as Error)
    } finally {
      setLoadingAction(undefined)
    }
  }

  return (
    <Modal
      opened={opened}
      onClose={onClose}
      title={title}
      withCloseButton={!!title}
      closeOnClickOutside={false}
    >
      <Stack gap='md'>
        <FocusTrap.InitialFocus />

        <Stack fz='sm' gap='xs'>
          {message}
          {error && <Text size="sm" c="red"> {formatError(error)} </Text>}
        </Stack>

        <Group justify='flex-end'>
          {actions.map(action => {
            const [variant, color]: [ButtonVariant, DefaultMantineColor | undefined] = (() => {
              const role = action.role ?? 'confirm'

              switch (role) {
                case 'cancel': return ['default', undefined]
                case 'confirm': return ['filled', undefined /* theme color */]
                case 'destructive': return ['filled', 'red']
              }
            })()

            return (
              <Button
                variant={variant}
                color={color}
                onClick={() => handleActionClick(action)}
                loading={loadingAction === action}
                disabled={loadingAction !== undefined}
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
    role?: 'cancel' | 'confirm' | 'destructive'
    handler: () => void | Promise<void>
  }
}