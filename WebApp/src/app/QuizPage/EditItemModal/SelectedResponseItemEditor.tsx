import { useEffect, useRef, useState } from 'react'
import { DragDropContext, Droppable, Draggable, DropResult, DraggableProvided } from '@hello-pangea/dnd'
import { Text, TextInput, Button, ActionIcon, Group, Box, Stack, Paper, Textarea } from '@mantine/core'
import { IconGripVertical, IconTrash, IconPlus } from '@tabler/icons-react'
import { ObjectId } from 'bson'

import { Quiz } from 'src/models/Quiz'
import { produce } from 'immer'
import PromptInput from 'src/app/QuizPage/EditItemModal/PromptInput'

type Option = Quiz.SelectedResponseItem['data']['options'][number]

export default function SelectedResponseItemEditor({ item, onChange, promptRef }: {
  item: Quiz.SelectedResponseItem,
  onChange: (_: Quiz.SelectedResponseItem) => void
  promptRef?: React.Ref<HTMLTextAreaElement>
}) {
  const optionTextareaRefs = useRef<Record<string, HTMLInputElement | null>>({})

  function handlePromptChange(value: string) {
    const modifiedItem = produce(item, item => {
      item.data.prompt = value
    })

    onChange(modifiedItem)
  }

  function handleAddOption() {
    const newOption = { id: new ObjectId().toString(), value: '' }

    const modifiedItem = produce(item, item => {
      item.data.options.push(newOption)
    })

    onChange(modifiedItem)

    // Focus next tick
    requestAnimationFrame(() => {
      optionTextareaRefs.current[newOption.id]?.focus()
    })
  }

  function handleDeleteOption(id: string) {
    const modifiedItem = produce(item, item => {
      item.data.options = item.data.options.filter(x => x.id != id)
    })

    onChange(modifiedItem)
  }

  function handleOptionChange(option: Option) {
    const modifiedItem = produce(item, item => {
      const index = item.data.options.findIndex(x => x.id == option.id)!
      item.data.options[index] = option
    })

    onChange(modifiedItem)
  }

  function onDragEnd(result: DropResult) {
    if (!result.destination) {
      return
    }

    const from = result.source.index
    const to = result.destination.index

    if (from === to) {
      return
    }

    const modifiedItem = produce(item, item => {
      const options = Array.from(item.data.options)
      const [moved] = options.splice(from, 1)
      options.splice(to, 0, moved)
      item.data.options = options
    })

    onChange(modifiedItem)
  }

  return (
    <Stack>
      {/* Prompt */}
      <PromptInput value={item.data.prompt} onChange={handlePromptChange} ref={promptRef}/>
      {/* Options */}
      <DragDropContext onDragEnd={onDragEnd}>
        <Droppable
          droppableId='droppable-list'
          // Need this for drag drop to work inside Mantine modal
          // https://github.com/hello-pangea/dnd/issues/560#issuecomment-3353933696
          // https://github.com/hello-pangea/dnd/blob/main/docs/guides/reparenting.md
          renderClone={(provided, snapshot, rubric) => {
            const option = item.data.options[rubric.source.index]

            return (
              <Row
                option={option}
                onChange={e => { }}
                onDelete={() => { }}
                provided={provided}
              />
            )
          }}
        >
          {(provided) => (
            <div
              ref={provided.innerRef}
              {...provided.droppableProps}
              style={{ width: '100%' }}
            >
              <Stack gap='0.2rem'>
                <Text fz='sm' fw='500'>Options</Text>

                <Stack gap='0.4rem'>
                  {item.data.options.map((option, index) => (
                    <Draggable key={option.id} draggableId={option.id} index={index}>
                      {(provided, snapshot) => (
                        <Row
                          option={option}
                          onChange={modifiedOption => handleOptionChange(modifiedOption)}
                          onDelete={() => handleDeleteOption(option.id)}
                          provided={provided}
                          ref={el => (optionTextareaRefs.current[option.id] = el)}
                        />
                      )}
                    </Draggable>
                  ))}
                  {provided.placeholder}
                </Stack>

                <Button
                  variant='default'
                  leftSection={<IconPlus size={16} />}
                  onClick={handleAddOption}
                  mr='auto'
                  mt='0.3rem'
                >
                  Add Option
                </Button>
              </Stack>
            </div>
          )}
        </Droppable>
      </DragDropContext>
    </Stack>
  )
}

function Row({ option, onChange, onDelete, provided, ref }: {
  option: Option,
  onChange: (_: Option) => void,
  onDelete: () => void,
  provided: DraggableProvided,
  ref?: (_: HTMLInputElement) => void
}) {
  return (
    <Paper
      ref={provided.innerRef}
      {...provided.draggableProps}
    // shadow={snapshot.isDragging ? "md" : "sm"}
    >
      <Group gap='xs'>
        <Group style={{ flex: 1 }}>
          <TextInput
            placeholder='Type something...'
            w='100%'
            size='sm'
            value={option.value}
            onChange={e => {
              const updatedOption = { ...option, value: e.currentTarget.value }
              onChange(updatedOption)
            }}
            ref={ref}
          />
        </Group>

        <ActionIcon
          variant='default'
          size='lg'
          onClick={onDelete}
          title='Delete'
        >
          <IconTrash size={16} />
        </ActionIcon>

        {/* Drag handle on the right */}
        <ActionIcon
          {...provided.dragHandleProps}
          variant='default'
          size='lg'
          title='Drag'
        >
          <IconGripVertical size={18} />
        </ActionIcon>
      </Group>
    </Paper>
  )
}