import { Button, FocusTrap, Group, Modal, Stack, Text } from '@mantine/core'
import { Blocker } from 'react-router'
import formatError from 'src/common/format-error'

export function UnsavedChangesModal({ blocker, save, saving, saveError }: {
  blocker: Blocker
  save: () => void
  saving: boolean
  saveError: Error | null
}) {
  return (
    <Modal
      opened={blocker.state === 'blocked'}
      onClose={() => blocker.reset?.()}
      title='Unsaved Changes'
      closeOnClickOutside={false}
    >
      <Stack gap='md'>
        <FocusTrap.InitialFocus />

        <Stack fz='sm' gap='xs'>
          <Text>You have unsaved changes. Discard?</Text>
        </Stack>

        {saveError && (
          <Text size='sm' c='red'>
            {formatError(saveError)}
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
            onClick={save}
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
