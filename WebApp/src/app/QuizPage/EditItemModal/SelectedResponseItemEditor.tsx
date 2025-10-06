import { useRef } from 'react'
import { DragDropContext, Droppable, Draggable, DropResult, DraggableProvided } from '@hello-pangea/dnd'
import { Text, TextInput, Button, ActionIcon, Group, Box, Stack, Paper } from '@mantine/core'
import { IconGripVertical, IconTrash, IconPlus } from '@tabler/icons-react'
import { ObjectId } from 'bson'

import { Quiz } from 'src/models/Quiz'

type Option = Quiz.SelectedResponseItem['data']['options'][number]

export default function SelectedResponseItemEditor({ options, setOptions }: {
  options: Option[],
  setOptions: (_: Option[]) => void
}) {
  const refs = useRef<Record<string, HTMLInputElement | null>>({})

  function handleAdd() {
    const newOption = { id: new ObjectId().toString(), value: '' }
    setOptions([...options, newOption])

    // Focus next tick
    requestAnimationFrame(() => {
      refs.current[newOption.id]?.focus()
    })
  }

  function handleDelete(id: string) {
    setOptions(options.filter(x => x.id != id))
  }

  function handleChange(option: Option) {
    setOptions(options.map(x => x.id == option.id ? option : x))
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

    const copy = Array.from(options)
    const [moved] = copy.splice(from, 1)
    copy.splice(to, 0, moved)

    setOptions(copy)
  }

  return (
    <Box>
      <DragDropContext onDragEnd={onDragEnd}>
        <Droppable
          droppableId='droppable-list'
          // Need this for drag drop to work inside Mantine modal
          // https://github.com/hello-pangea/dnd/issues/560#issuecomment-3353933696
          // https://github.com/hello-pangea/dnd/blob/main/docs/guides/reparenting.md
          renderClone={(provided, snapshot, rubric) => {
            const option = options.find(x => x.id == options[rubric.source.index].id)!

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
                  {options.map((option, index) => (
                    <Draggable key={option.id} draggableId={option.id} index={index}>
                      {(provided, snapshot) => (
                        <Row
                          option={option}
                          onChange={modifiedOption => handleChange(modifiedOption)}
                          onDelete={() => handleDelete(option.id)}
                          provided={provided}
                          ref={el => (refs.current[option.id] = el)}
                        />
                      )}
                    </Draggable>
                  ))}
                  {provided.placeholder}
                </Stack>

                <Button
                  variant='default'
                  leftSection={<IconPlus size={16} />}
                  onClick={handleAdd}
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
    </Box>
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