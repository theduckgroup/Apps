import { useRef, useState } from 'react'
import { Text, Stack, Paper, Group, ActionIcon, Button, Menu } from '@mantine/core'
import { DragDropContext, Droppable, Draggable, DropResult, DraggableProvided } from '@hello-pangea/dnd'
import { ObjectId } from 'bson'

import { Quiz } from 'src/models/Quiz'
import { IconChevronDown, IconChevronRight, IconGripVertical, IconPlus, IconTrash } from '@tabler/icons-react'
import { produce } from 'immer'
import SelectedResponseItemEditor from 'src/app/QuizPage/EditItemModal/SelectedResponseItemEditor'
import TextInputItemEditor from 'src/app/QuizPage/EditItemModal/TextInputItemEditor'
import PromptInput from 'src/app/QuizPage/EditItemModal/PromptInput'

export default function ListItemEditor({ item, onChange }: {
  item: Quiz.ListItem,
  onChange: (_: Quiz.ListItem) => void
}) {
  const promptRefs = useRef<Record<string, HTMLTextAreaElement | null>>({})
  const [subitemExpandedMap, setSubitemExpandedMap] = useState<Record<string, boolean | undefined>>({})

  function handlePromptChange(value: string) {
    const modifiedItem = produce(item, item => {
      item.data.prompt = value
    })

    onChange(modifiedItem)
  }

  function handleAddSubitem(kind: Quiz.SelectedResponseItem['kind'] | Quiz.TextInputItem['kind']) {
    const newSubitem = Quiz.createDefaultItem(kind)

    const modifiedItem = produce(item, item => {
      item.data.items.push(newSubitem)
    })

    onChange(modifiedItem)
    setSubitemExpanded(newSubitem.id, true)

    // Focus next tick
    requestAnimationFrame(() => {
      promptRefs.current[newSubitem.id]?.focus()
    })
  }

  function handleDeleteSubitem(id: string) {
    const modifiedItem = produce(item, item => {
      item.data.items = item.data.items.filter(x => x.id != id)
    })

    onChange(modifiedItem)
  }

  function handleSubitemChange(subitem: Quiz.Item) {
    const modifiedItem = produce(item, item => {
      const index = item.data.items.findIndex(x => x.id == subitem.id)
      item.data.items[index] = subitem
    })

    onChange(modifiedItem)
  }

  function isExpanded(id: string) {
    return subitemExpandedMap[id] ?? false
  }

  function setSubitemExpanded(id: string, value: boolean) {
    const copy = { ...subitemExpandedMap }
    copy[id] = value
    setSubitemExpandedMap(copy)
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
      const copy = Array.from(item.data.items)
      const [moved] = copy.splice(from, 1)
      copy.splice(to, 0, moved)
      item.data.items = copy
    })

    onChange(modifiedItem)
  }

  return (
    <Stack>
      {/* Prompt */}
      <PromptInput value={item.data.prompt} onChange={handlePromptChange} />
      {/* Subitems */}
      <DragDropContext onDragEnd={onDragEnd}>
        <Droppable
          droppableId='droppable-list'
          // Need this for drag drop to work inside Mantine modal
          // https://github.com/hello-pangea/dnd/issues/560#issuecomment-3353933696
          // https://github.com/hello-pangea/dnd/blob/main/docs/guides/reparenting.md
          renderClone={(provided, snapshot, rubric) => {
            const subitem = item.data.items[rubric.source.index]
            const index = item.data.items.findIndex(x => x.id == subitem.id)!

            return (
              <Row
                item={subitem}
                index={index}
                onChange={e => { }}
                onDelete={() => { }}
                expanded={isExpanded(subitem.id)}
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
              {item.data.items.map((subitem, index) => (
                <Draggable key={subitem.id} draggableId={subitem.id} index={index}>
                  {(provided, snapshot) => (
                    <Row
                      item={subitem}
                      index={index}
                      onChange={handleSubitemChange}
                      onDelete={() => handleDeleteSubitem(subitem.id)}
                      expanded={subitemExpandedMap[subitem.id] ?? false}
                      setExpanded={value => setSubitemExpanded(subitem.id, value)}
                      provided={provided}
                      promptRef={el => (promptRefs.current[subitem.id] = el)}
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
                    Add Sub Item
                  </Button>
                </Menu.Target>
                <Menu.Dropdown>
                  <Menu.Item
                    onClick={() => handleAddSubitem('selectedResponseItem')}
                  >
                    Multiple Choice
                  </Menu.Item>
                  <Menu.Item
                    onClick={() => handleAddSubitem('textInputItem')}
                  >
                    Text Input
                  </Menu.Item>
                </Menu.Dropdown>
              </Menu>

            </Stack>
          )}
        </Droppable>
      </DragDropContext >
    </Stack>
  )
}

function Row({ item, index, onChange, onDelete, expanded, setExpanded, provided, promptRef }: {
  item: Quiz.Item,
  index: number,
  onChange: (_: Quiz.Item) => void,
  onDelete: () => void,
  expanded: boolean,
  setExpanded: (_: boolean) => void,
  provided: DraggableProvided,
  promptRef?: (_: HTMLTextAreaElement) => void
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
              {/* Content */}
              {(() => {
                switch (item.kind) {
                  case 'selectedResponseItem':
                    return (
                      <SelectedResponseItemEditor item={item} onChange={onChange} promptRef={promptRef}/>
                    )

                  case 'textInputItem':
                    return (
                      <TextInputItemEditor item={item} onChange={onChange} promptRef={promptRef} />
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