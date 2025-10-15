import { Quiz } from 'src/quiz-app/models/Quiz'
import { produce } from 'immer'
import PromptInput from './PromptInput'
import { Checkbox, Stack } from '@mantine/core'

export default function TextInputItemEditor({ item, onChange, promptRef }: {
  item: Quiz.TextInputItem,
  onChange: (_: Quiz.TextInputItem) => void
  promptRef?: React.Ref<HTMLTextAreaElement>
}) {
  function handlePromptChange(value: string) {
    const modifiedItem = produce(item, item => {
      item.data.prompt = value
    })

    onChange(modifiedItem)
  }

  function handleInlineChange(value: boolean) {
    const modifiedItem = produce(item, item => {
      item.data.layout = value ? 'inline' : 'stack'
    })

    onChange(modifiedItem)
  }

  return (
    <Stack>
      <PromptInput value={item.data.prompt} onChange={handlePromptChange} ref={promptRef} />
      <Checkbox
        label='Inline'
        checked={item.data.layout == 'inline'}
        onChange={e => handleInlineChange(e.currentTarget.checked)}
      />
    </Stack>
  )
}
