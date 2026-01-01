import { useViewportSize } from '@mantine/hooks'
import { useElementRect } from './use-element-rect'
import { Button, Text } from '@mantine/core'
import formatError from 'src/common/format-error'

export function EditorFooter({ editorRef, hasUnsavedChanges, save, isSaving, saveError }: {
  editorRef: React.RefObject<HTMLElement | null>
  hasUnsavedChanges: boolean
  save: () => void
  isSaving: boolean
  saveError: Error | null
}) {
  const viewportSize = useViewportSize()
  const editorRect = useElementRect(editorRef)

  return (
    <>
      <div className='h-26' />
      <div
        className='
          fixed left-0 right-0 bottom-0 h-22 pb-[env(safe-area-inset-bottom)]
          bg-[var(--mantine-color-dark-7)]
        '
        style={{
          paddingLeft: editorRect?.left ?? 0,
          paddingRight: viewportSize.width - (editorRect?.right ?? 0)
        }}
      >
        <div className='w-full h-full flex flex-row justify-between items-center px-4 py-4 gap-4'>
          {saveError ? <Text c='red' lineClamp={2} lh='xs'>{formatError(saveError)}</Text> : <div />}
          <Button
            onClick={save}
            loading={isSaving}
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
