import { useState } from 'react'
import { useViewportSize } from '@mantine/hooks'
import { useElementRect } from './use-element-rect'
import { Button, Text } from '@mantine/core'
import formatError from 'src/common/format-error'

export function EditorFooter({ editorRef, hasUnsavedChanges, save }: {
  editorRef: React.RefObject<HTMLElement | null>
  hasUnsavedChanges: boolean
  save: () => Promise<void>
}) {
  const viewportSize = useViewportSize()
  const editorRect = useElementRect(editorRef)
  const height = 80

  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  async function handleSave() {
    try {
      setError(null)
      setSaving(true)
      await save()
    } catch (e) {
      setError(e as Error)
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <div className='mt-6' style={{ height: height }} />
      <div
        className='
          fixed left-0 right-0 bottom-0 pb-[env(safe-area-inset-bottom)]
          bg-[var(--mantine-color-dark-7)]
          border-t border-neutral-700
        '
        style={{
          height: height,
          paddingLeft: editorRect?.left ?? 0,
          paddingRight: viewportSize.width - (editorRect?.right ?? 0)
        }}
      >
        <div className='w-full h-full flex flex-row justify-between items-center px-4 pt-3 pb-6 gap-4'>
          {error ? <Text c='red' lineClamp={2} lh='xs'>{formatError(error)}</Text> : <div />}
          <Button
            onClick={handleSave}
            loading={saving}
            disabled={!hasUnsavedChanges}
            className='flex-none'
          >
            Save Changes
          </Button>
        </div>
      </div>
    </>
  )
}
