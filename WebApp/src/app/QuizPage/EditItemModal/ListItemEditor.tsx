import { useRef, useState } from 'react'
import { Text, Stack, Paper, Group, ActionIcon, Button, Menu, Box, Anchor } from '@mantine/core'
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
  const [expandedSubitemIDs, setExpandedSubitemIDs] = useState<Set<string>>(new Set())

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

  function isSubitemExpanded(id: string) {
    return expandedSubitemIDs.has(id)
  }

  // function areAllSubitemsExpanded() {
  //   function areEqual(a: Set<string>, b: Set<string>) {
  //     return a.size == b.size && a.forEach(x => b.has(x))
  //   }

  //   const allSubitemIDs = new Set(item.data.items.map(x => x.id))
  //   return areEqual(expandedSubitemIDs, allSubitemIDs)
  // }

  function setSubitemExpanded(id: string, value: boolean) {
    const modified = produce(expandedSubitemIDs, set => {
      if (value) {
        set.add(id)
      } else {
        set.delete(id)
      }
    })

    setExpandedSubitemIDs(modified)
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
      <Stack gap='0.25rem'>
        {/* Label */}
        <Group gap='md'>
          <Text fz='sm'>Sub Items</Text>
          {/* <Anchor onClick={e => { e.preventDefault(); expandCollapseAllSubitems() }}>Expand/Collapse</Anchor> */}
        </Group>

        {/* List */}
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
                  expanded={isSubitemExpanded(subitem.id)}
                  setExpanded={() => { }}
                  provided={provided}
                  mb={0}
                />
              )
            }}
          >
            {(provided) => (
              <Stack
                ref={provided.innerRef}
                {...provided.droppableProps}
                style={{ width: '100%' }}
                // gap='xs'
                gap={0}
              >
                {item.data.items.map((subitem, index) => (
                  <Draggable key={subitem.id} draggableId={subitem.id} index={index}>
                    {(provided, snapshot) => (
                      <Row
                        item={subitem}
                        index={index}
                        onChange={handleSubitemChange}
                        onDelete={() => handleDeleteSubitem(subitem.id)}
                        expanded={isSubitemExpanded(subitem.id)}
                        setExpanded={value => setSubitemExpanded(subitem.id, value)}
                        provided={provided}
                        promptRef={el => (promptRefs.current[subitem.id] = el)}
                        mb={index < item.data.items.length ? 'xs' : 0}
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
    </Stack>
  )
}

function Row({ item, index, onChange, onDelete, expanded, setExpanded, provided, promptRef, mb }: {
  item: Quiz.Item,
  index: number,
  onChange: (_: Quiz.Item) => void,
  onDelete: () => void,
  expanded: boolean,
  setExpanded: (_: boolean) => void,
  provided: DraggableProvided,
  promptRef?: (_: HTMLTextAreaElement) => void
  mb: string | number
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
      mb={mb}
    >
      <Stack
        gap='0.25rem'
      // shadow={snapshot.isDragging ? "md" : "sm"}
      >
        {/* Expand button + Title + Trash button+ Drag handle */}
        <Group gap='xs'>
          <Group gap='0.25rem' mr='auto'>
            {/* Expand button */}
            <ActionIcon
              variant='transparent'
              color='gray'
              size='compact-md'
              pl={0}
              tabIndex={-1}
              onClick={() => setExpanded(!expanded)}
            >
              {expanded ? <IconChevronDown size={18} /> : <IconChevronRight size={18} />}
            </ActionIcon>
            {/* Title */}
            {
              expanded ?
                <Text fw='bold' fz='sm' mr='auto'>{index + 1}. {kindLabel}</Text>
                :
                <Group fz='sm' gap='0.25rem'>
                  <Text lineClamp={1}>{item.data.prompt}</Text>
                </Group>
            }

          </Group>
          {/* Trash button */}
          <ActionIcon
            variant='default'
            size='md'
            onClick={onDelete}
            title='Delete'
            tabIndex={-1}
          >
            <IconTrash size={16} />
          </ActionIcon>
          {/* Drag handle */}
          <Box
            {...provided.dragHandleProps}
            tabIndex={-1}
          >
            <IconGripVertical size={18} />
          </Box>
        </Group>

        {
          expanded ? (
            <>
              {/* Content */}
              {(() => {
                switch (item.kind) {
                  case 'selectedResponseItem':
                    return <SelectedResponseItemEditor item={item} onChange={onChange} promptRef={promptRef} />

                  case 'textInputItem':
                    return <TextInputItemEditor item={item} onChange={onChange} promptRef={promptRef} />

                  case 'listItem':
                    return <Text c='red'>ERROR: Unexpected item type</Text>
                }
              })()}
            </>
          ) : (
            <>
              {/* Readonly prompt */}
              {/* {item.data.prompt ? <Text fz='sm'>{item.data.prompt}</Text> : null} */}
            </>
          )
        }
      </Stack>
    </Paper>
  )
}