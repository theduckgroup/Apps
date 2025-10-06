import { useRef, useState } from 'react'
import { Text, Stack, Paper, Group, Textarea, ActionIcon, Button, Menu } from '@mantine/core'
import { DragDropContext, Droppable, Draggable, DropResult, DraggableProvided } from '@hello-pangea/dnd'
import { ObjectId } from 'bson'

import { Quiz } from 'src/models/Quiz'
import { IconChevronDown, IconChevronRight, IconGripVertical, IconPlus, IconTrash } from '@tabler/icons-react'
import { produce } from 'immer'
import SelectedResponseItemEditor from 'src/app/QuizPage/EditItemModal/SelectedResponseItemEditor'
import TextInputItemEditor from 'src/app/QuizPage/EditItemModal/TextInputItemEditor'

export default function ListItemEditor({ items, setItems }: {
  items: Quiz.Item[],
  setItems: (_: Quiz.Item[]) => void
}) {
  const promptRefs = useRef<Record<string, HTMLTextAreaElement | null>>({})
  const [expandedMap, setExpandedMap] = useState<Record<string, boolean | undefined>>({})

  function handleAddSelectedResponseItem() {
    const newItem: Quiz.Item = {
      id: new ObjectId().toString(),
      kind: 'selectedResponseItem',
      data: {
        prompt: '',
        options: [],
        optionsPerRow: 1,
      }
    }

    setItems([...items, newItem])
    setExpanded(newItem.id, true)

    // Focus next tick
    requestAnimationFrame(() => {
      promptRefs.current[newItem.id]?.focus()
    })
  }

  function handleAddTextInputItem() {
    const newItem: Quiz.Item = {
      id: new ObjectId().toString(),
      kind: 'textInputItem',
      data: {
        prompt: ''
      }
    }

    setItems([...items, newItem])
    setExpanded(newItem.id, true)

    // Focus next tick
    requestAnimationFrame(() => {
      promptRefs.current[newItem.id]?.focus()
    })
  }

  function handleDelete(id: string) {
    const newItems = items.filter(x => x.id != id)
    setItems(newItems)
  }

  function setItem(item: Quiz.Item) {
    const newItems = items.map(x => x.id == item.id ? item : x)
    setItems(newItems)
  }

  function isExpanded(id: string) {
    return expandedMap[id] ?? false
  }

  function setExpanded(id: string, value: boolean) {
    const copy = { ...expandedMap }
    copy[id] = value
    setExpandedMap(copy)
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

    const copy = Array.from(items)
    const [moved] = copy.splice(from, 1)
    copy.splice(to, 0, moved)
    setItems(items)
  }

  return (
    <DragDropContext onDragEnd={onDragEnd}>
      <Droppable
        droppableId='droppable-list'
        // Need this for drag drop to work inside Mantine modal
        // https://github.com/hello-pangea/dnd/issues/560#issuecomment-3353933696
        // https://github.com/hello-pangea/dnd/blob/main/docs/guides/reparenting.md
        renderClone={(provided, snapshot, rubric) => {
          const index = items.findIndex(x => x.id == items[rubric.source.index].id)!
          const item = items[index]

          return (
            <Row
              item={item}
              index={index}
              setItem={e => { }}
              onDelete={() => { }}
              expanded={isExpanded(item.id)}
              setExpanded={() => { }}
              provided={provided}
            />
          )
        }}
      >
        {(provided) => (
          <Stack
            ref={provided.innerRef}
            {...provided.droppableProps}
            style={{ width: '100%' }}
            gap='xs'
          >
            {items.map((item, index) => (
              <Draggable key={item.id} draggableId={item.id} index={index}>
                {(provided, snapshot) => (
                  <Row
                    item={item}
                    index={index}
                    setItem={setItem}
                    onDelete={() => handleDelete(item.id)}
                    expanded={expandedMap[item.id] ?? false}
                    setExpanded={value => setExpanded(item.id, value)}
                    provided={provided}
                    ref={el => (promptRefs.current[item.id] = el)}
                  />
                )}
              </Draggable>
            ))}
            {provided.placeholder}

            <Menu offset={6} position='right-start'>
              <Menu.Target>
                <Button
                  variant='default'
                  size='sm'
                  leftSection={<IconPlus size={16} />}
                  mr='auto'
                >
                  Add Item
                </Button>
              </Menu.Target>
              <Menu.Dropdown>
                <Menu.Item onClick={handleAddSelectedResponseItem}>
                  Multiple Choice
                </Menu.Item>
                <Menu.Item onClick={handleAddTextInputItem}>
                  Text Input
                </Menu.Item>
              </Menu.Dropdown>
            </Menu>

          </Stack>
        )}
      </Droppable>
    </DragDropContext >
  )
}

function Row({ item, index, setItem, onDelete, expanded, setExpanded, provided, ref }: {
  item: Quiz.Item,
  index: number,
  setItem: (_: Quiz.Item) => void,
  onDelete: () => void,
  expanded: boolean,
  setExpanded: (_: boolean) => void,
  provided: DraggableProvided,
  ref?: (_: HTMLTextAreaElement) => void
}) {
  const kindLabel = (() => {
    switch (item.kind) {
      case 'selectedResponseItem': return 'Multiple Choice'
      case 'textInputItem': return 'Text Input'
      case 'listItem': return 'List'
    }
  })()

  return (
    <Paper
      ref={provided.innerRef}
      {...provided.draggableProps}
      withBorder
      p='sm'
    >
      <Stack
        gap='0.5rem'
      // shadow={snapshot.isDragging ? "md" : "sm"}
      >
        {/* Item number + trash + drag */}
        <Group gap='xs'>
          <Group gap='0.25rem' mr='auto'>
            <ActionIcon
              variant='transparent'
              color='gray'
              size='compact-md'
              onClick={() => setExpanded(!expanded)}
            >
              {
                expanded ?
                  <IconChevronDown size={18} /> :
                  <IconChevronRight size={18} />
              }

            </ActionIcon>
            <Text fw='bold' fz='sm' mr='auto'>Item {index + 1} - {kindLabel}</Text>
          </Group>
          <ActionIcon
            variant='default'
            size='md'
            onClick={onDelete}
            title='Delete'
          >
            <IconTrash size={16} />
          </ActionIcon>
          {/* Drag handle on the right */}
          <ActionIcon
            {...provided.dragHandleProps}
            variant='default'
            size='md'
            title='Drag'
          >
            <IconGripVertical size={18} />
          </ActionIcon>
        </Group>

        {
          expanded ? (
            <>
              {/* Prompt */}
              <Textarea
                label='Prompt'
                w='100%'
                autosize
                minRows={1}
                value={item.data.prompt}
                onChange={e => {
                  const item1 = produce(item, item => {
                    item.data.prompt = e.currentTarget.value
                  })
                  setItem(item1)
                }}
                ref={ref}
              />

              {/* Content */}
              {(() => {
                switch (item.kind) {
                  case 'selectedResponseItem':
                    return (
                      <SelectedResponseItemEditor
                        options={item.data.options}
                        setOptions={options => {
                          const item1 = produce(item, item => { item.data.options = options })
                          setItem(item1)
                        }}
                      />
                    )

                  case 'textInputItem':
                    return (
                      <TextInputItemEditor />
                    )

                  case 'listItem':
                    return (
                      <Text c='red'>ERROR: Unexpected item type</Text>
                    )
                }
              })()}
            </>
          ) : (
            <>
              {/* Readonly prompt */}
              {item.data.prompt ? <Text fz='sm'>{item.data.prompt}</Text> : null}
            </>
          )
        }

      </Stack>
    </Paper>
  )
}