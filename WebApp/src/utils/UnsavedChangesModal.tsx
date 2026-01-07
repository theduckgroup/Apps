import { useState } from 'react'
import { Button, FocusTrap, Group, Modal, Stack, Text } from '@mantine/core'
import { Blocker } from 'react-router'
import formatError from 'src/common/format-error'

export function UnsavedChangesModal({ blocker, save }: {
  blocker: Blocker
  save: () => Promise<void>
}) {
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  async function handleSave() {
    try {
      setError(null)
      setSaving(true)
      await save()
      blocker.proceed?.()
    } catch (e) {
      setError(e as Error)
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal
      opened={blocker.state === 'blocked'}
      onClose={() => blocker.reset?.()}
      title='Unsaved Changes'
      size='md'
      closeOnClickOutside={false}
    >
      <Stack gap='md'>
        <FocusTrap.InitialFocus />

        <Stack fz='sm' gap='xs'>
          <Text>You have unsaved changes.</Text>
        </Stack>

        {error && (
          <Text size='sm' c='red'>
            {formatError(error)}
          </Text>
        )}

        <Group justify='flex-end'>
          <Button
            variant='default'
            onClick={() => blocker.reset?.()}
            disabled={saving}
          >
            Cancel
          </Button>
          <Button
            variant='filled'
            color='red'
            onClick={() => blocker.proceed?.()}
            disabled={saving}
          >
            Discard Changes
          </Button>
          <Button
            variant='filled'
            onClick={handleSave}
            loading={saving}
            disabled={saving}
          >
            Save Changes
          </Button>
        </Group>
      </Stack>
    </Modal>
  )
}
