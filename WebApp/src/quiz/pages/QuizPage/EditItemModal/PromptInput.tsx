import { useEffect, useRef } from 'react'
import { Textarea } from '@mantine/core'
import { useMergedRef } from '@mantine/hooks'

export default function PromptInput({ value, onChange, ref }: {
  value: string,
  onChange: (_: string) => void
  ref?: React.Ref<HTMLTextAreaElement>
}) {
  const localRef = useRef<HTMLTextAreaElement | null>(null)

  useEffect(() => {
    // Auto focus only if ref is not passed
    if (!ref) {
      setTimeout(() => {
        localRef.current?.focus()
      }, 50)
    }
  }, [ref])

  return (
    <Textarea
      label='Prompt'
      autosize
      value={value}
      onChange={e => onChange(e.currentTarget.value)}
      ref={useMergedRef(ref, localRef)}
    />
  )
}