import { Quiz } from 'src/quiz-app/models/Quiz'
import { produce } from 'immer'
import PromptInput from './PromptInput'

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

  return (
    <>
      <PromptInput value={item.data.prompt} onChange={handlePromptChange} ref={promptRef} />
    </>
  )
}
