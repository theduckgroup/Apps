import { useEffect, useRef, useState } from "react"
import { Button, Modal, Select, Stack, Textarea } from "@mantine/core"
import { Quiz } from 'src/models/Quiz'

import ListItemEditor from './ListItemEditor'
import SelectedResponseItemEditor from './SelectedResponseItemEditor'
import TextInputItemEditor from './TextInputItemEditor'

export default function EditItemModal({ opened, close, options }: {
  opened: boolean,
  close: () => void,
  options: EditItemModalOptions
}) {
  interface ItemKind {
    value: Quiz.Item['kind']
    label: string
  }

  const itemKinds: ItemKind[] = [
    {
      value: 'selectedResponseItem',
      label: 'Multiple Choice'
    },
    {
      value: 'textInputItem',
      label: 'Text Input'
    },
    {
      value: 'listItem',
      label: 'List'
    },
  ]

  type Option = Quiz.SelectedResponseItem['data']['options'][number]

  const [itemKind, setItemKind] = useState<ItemKind>(itemKinds[0])
  const [prompt, setPrompt] = useState('')
  const [subitems, setSubitems] = useState<Quiz.Item[]>([])
  const [srOptions, setSROptions] = useState<Option[]>([]) // SR = Selected response
  const promptRef = useRef<HTMLTextAreaElement | null>(null)

  useEffect(() => {
    setTimeout(() => {
      if (promptRef.current && opened) {
        promptRef.current?.focus()
      }
    }, 50)

  }, [opened])

  function handleSubmit() {
    close()

    switch (itemKind.value) {
      case 'listItem': {
        const item: EditItemModalData = {
          kind: itemKind.value,
          data: {
            prompt,
            items: [] as Quiz.Item[]
          }
        }

        options.onChange(item)

        break
      }

      case 'selectedResponseItem': {
        const item: EditItemModalData = {
          kind: itemKind.value,
          data: {
            prompt,
            options: srOptions,
            optionsPerRow: 1
          }
        }

        options.onChange(item)

        break
      }

      case 'textInputItem': {
        const item: EditItemModalData = {
          kind: itemKind.value,
          data: {
            prompt
          }
        }

        options.onChange(item)

        break
      }
    }
  }

  return (
    <Modal
      opened={opened}
      onClose={close}
      title={options?.title}
      size='lg'
      returnFocus={false}
      closeOnClickOutside={false}
    >
      <form onSubmit={e => { e.preventDefault(); handleSubmit() }}>
        <Stack gap='sm'>
          <Select
            label='Type'
            value={itemKind.value}
            onChange={value => setItemKind(itemKinds.find(x => x.value == value)!)}
            data={itemKinds}
            allowDeselect={false}
          />
          <Textarea
            label='Prompt'
            autosize
            value={prompt}
            onChange={e => setPrompt(e.currentTarget.value)}
          />
          {
            (() => {
              switch (itemKind.value) {
                case 'listItem':
                  return <ListItemEditor items={subitems} setItems={setSubitems} />

                case 'selectedResponseItem':
                  return <SelectedResponseItemEditor options={srOptions} setOptions={setSROptions} />

                case 'textInputItem':
                  return <TextInputItemEditor />
              }
            })()
          }
          <Button type='submit' ml='auto'>Save</Button>
        </Stack>
      </form>
    </Modal>
  )
}

export interface EditItemModalOptions {
  title: string
  data: EditItemModalData | null
  onChange: (data: EditItemModalData) => void
}

export type EditItemModalData = Omit<Quiz.ListItem, 'id'> | Omit<Quiz.SelectedResponseItem, 'id'> | Omit<Quiz.TextInputItem, 'id'>

export namespace EditItemModalOptions {
  export const empty: EditItemModalOptions = {
    title: '',
    data: null,
    onChange: () => { }
  }
}
