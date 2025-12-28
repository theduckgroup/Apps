import { useCallback, useMemo, useState } from 'react'
import { ActionIcon, Box, Button, Divider, Group, Menu, Paper, Stack, Text, Title } from '@mantine/core'
import { DragDropContext, Draggable, DraggableProvided, DraggableProvidedDragHandleProps, Droppable, DropResult } from '@hello-pangea/dnd'
import { IconChevronDown, IconChevronRight, IconDots, IconListNumbers, IconPencil, IconPlus, IconSelector, IconSquareCheck, IconSquareLetterT, IconTrash } from '@tabler/icons-react'
import { produce } from 'immer'

import { Quiz } from 'src/quiz-app/models/Quiz'
import { EditItemModal } from './EditItemModal'
import { EditSectionModal } from './EditSectionModal'
import { ConfirmModal } from 'src/utils/ConfirmModal'
import ReadonlyItemComponent from './ReadonlyItemComponent'
import { Dispatch, Reducer } from 'src/utils/types-lib'
import useModal from 'src/utils/use-modal'

/**
 * Quiz sections & items editor component.
 */
export default function QuizItemsEditor({ items, sections, setData }: {
  items: Quiz.Item[],
  sections: Quiz.Section[],
  setData: Dispatch<Reducer<[Quiz.Item[], Quiz.Section[]]>>
}) {
  const editSectionModal = useModal(EditSectionModal)

  // Can't hold this inside SectionHeader or Row, otherwise the modal is gone when the SectionHeader/Row is deleted
  const confirmDeleteModal = useModal(ConfirmModal)

  // Can't hold this inside SectionComponent because it gets reset during drag/drop
  const [collapsedSectionIDs, setCollapsedSectionIDs] = useState(new Set<string>())

  const addSection: AddSectionFn = (newSection, anchor, position) => {
    setData(([items, sections]) => {
      const newSections = produce(sections, sections => {
        const anchorIndex = sections.findIndex(x => x.id == anchor.id)

        switch (position) {
          case 'before':
            sections.splice(anchorIndex, 0, newSection)
            break
          case 'after':
            sections.splice(anchorIndex + 1, 0, newSection)
            break
        }
      })

      return [items, newSections]
    })
  }

  const updateSection: UpdateSectionFn = (section) => {
    setData(([items, sections]) => {
      const newSections = [...sections]
      const sectionIndex = newSections.findIndex(x => x.id == section.id)!
      newSections[sectionIndex] = section

      return [items, newSections]
    })
  }

  const deleteSection: DeleteSectionFn = (section) => {
    setData(([items, sections]) => {
      const newSections = [...sections]
      const sectionIndex = newSections.findIndex(x => x.id == section.id)!
      newSections.splice(sectionIndex, 1)

      // Delete items in section
      const sectionItemIDs = new Set(section.rows.map(x => x.itemId))
      const newItems = items.filter(x => !sectionItemIDs.has(x.id))

      return [newItems, newSections]
    })

  }

  const addItem: AddItemFn = (item, afterItem) => {
    setData(([items, sections]) => {
      const newItems = [...items, item]

      const newSections = produce(sections, sections => {
        const newRow: Quiz.Row = {
          itemId: item.id
        }

        for (const section of sections) {
          const rowIndex = section.rows.findIndex(x => x.itemId == afterItem.id)

          if (rowIndex >= 0) {
            section.rows.splice(rowIndex + 1, 0, newRow)
          }
        }
      })

      return [newItems, newSections]
    })
  }

  const addItemToSection: AddItemToSectionFn = (item, section) => {
    setData(([items, sections]) => {
      const newItems = [...items, item]

      const newSections = produce(sections, sections => {
        const newRow: Quiz.Row = {
          itemId: item.id
        }

        const anchorSection = sections.find(x => x.id == section.id)!
        anchorSection.rows.push(newRow)
      })

      return [newItems, newSections]
    })
  }

  const updateItem: UpdateItemFn = (item) => {
    setData(([items, sections]) => {
      const newItems = produce(items, items => {
        const index = items.findIndex(x => x.id == item.id)
        items[index] = item
      })

      return [newItems, sections]
    })
  }

  const deleteItem: DeleteItemFn = (item) => {
    setData(([items, sections]) => {
      const newItems = produce(items, items => {
        const index = items.findIndex(x => x.id == item.id)!
        items.splice(index, 1)
      })

      const newSections = produce(sections, sections => {
        for (const section of sections) {
          const rowIndex = section.rows.findIndex(x => x.itemId == item.id)

          if (rowIndex != -1) {
            section.rows.splice(rowIndex, 1)
          }
        }
      })

      return [newItems, newSections]
    })
  }

  const onDragEnd = (result: DropResult) => {
    setData(([items, sections]) => {
      const { destination, source, type } = result

      if (!destination) {
        return [items, sections] // Dragged outside of a droppable area
      }

      if (destination.droppableId === source.droppableId && destination.index === source.index) {
        return [items, sections] // Dropped at the same position
      }

      if (type === 'row') {
        // Reordering rows within a section or moving between sections

        const sourceSectionId = source.droppableId
        const destinationSectionId = destination.droppableId

        const sourceSectionIndex = sections.findIndex(section => section.id === sourceSectionId)
        const destinationSectionIndex = sections.findIndex(section => section.id === destinationSectionId)

        const newSections = produce(sections, sections => {
          const [draggedItem] = sections[sourceSectionIndex].rows.splice(source.index, 1)
          sections[destinationSectionIndex].rows.splice(destination.index, 0, draggedItem)
        })

        return [items, newSections]

      } else if (type === 'section') {
        // Reordering sections

        const newSections = produce(sections, sections => {
          const [draggedSection] = sections.splice(source.index, 1)
          sections.splice(destination.index, 0, draggedSection)
        })

        return [items, newSections]

      } else {
        throw new Error('')
      }
    })
  }

  function isSectionExpanded(sectionId: string) {
    return !collapsedSectionIDs.has(sectionId)
  }

  function setSectionExpanded(sectionId: string, value: boolean) {
    const newValue = produce(collapsedSectionIDs, set => {
      if (value) {
        set.delete(sectionId)
      } else {
        set.add(sectionId)
      }
    })

    setCollapsedSectionIDs(newValue)
  }

  function handleClickAddSection() {
    editSectionModal.open({
      title: 'Add Section',
      section: Quiz.createDefaultSection(),
      onSave: newSection => {
        setData(([items, sections]) => {
          const newSections = [...sections, newSection]
          return [items, newSections]
        })
      }
    })
  }

  return (
    <>
      <DragDropContext onDragEnd={onDragEnd}>
        {/* Droppable of sections */}
        <Droppable
          droppableId='sections-droppable'
          direction='vertical'
          type='section'
          renderClone={(provided, snapshot, rubric) => {
            return (
              <Paper
                ref={provided.innerRef}
                {...provided.draggableProps}
                // bg='var(--mantine-color-gray-8)'
                bg='dark.5'
                h='4rem'
                radius='sm'
              />
            )
          }}
        >
          {provided => (
            // Stack of sections
            <Stack
              {...provided.droppableProps}
              ref={provided.innerRef}
              gap='md'
            >
              {sections.map((section, sectionIndex) => (
                // One section
                <Draggable key={section.id} draggableId={section.id} index={sectionIndex}>
                  {provided => (
                    <SectionComponent
                      section={section}
                      sectionIndex={sectionIndex}
                      itemForId={id => items.find(x => x.id == id)}
                      isExpanded={isSectionExpanded(section.id)}
                      setExpanded={value => setSectionExpanded(section.id, value)}
                      addSection={addSection}
                      updateSection={updateSection}
                      deleteSection={deleteSection}
                      addItem={addItem}
                      addItemToSection={addItemToSection}
                      updateItem={updateItem}
                      deleteItem={deleteItem}
                      openConfirmDeleteModal={confirmDeleteModal.open}
                      provided={provided}
                    />
                  )}
                </Draggable>
              ))}
              {provided.placeholder}

              {/* Add Section button */}
              <Button
                variant='default'
                size='sm'
                mr='auto'
                leftSection={<IconPlus size={13} />}
                onClick={handleClickAddSection}
              >
                Add Section
              </Button>
            </Stack>
          )}
        </Droppable>
      </DragDropContext>

      {/* Modals */}
      {editSectionModal.element}
      {confirmDeleteModal.element}
    </>
  )
}

function SectionComponent({
  section, sectionIndex, itemForId,
  isExpanded, setExpanded,
  addSection, updateSection, deleteSection,
  addItem, addItemToSection, updateItem, deleteItem,
  openConfirmDeleteModal,
  provided
}: {
  section: Quiz.Section,
  sectionIndex: number,
  itemForId: (id: string) => Quiz.Item | undefined,
  isExpanded: boolean,
  setExpanded: (_: boolean) => void,
  addSection: AddSectionFn,
  updateSection: UpdateSectionFn,
  deleteSection: DeleteSectionFn,
  addItem: AddItemFn,
  addItemToSection: AddItemToSectionFn,
  updateItem: UpdateItemFn,
  deleteItem: UpdateItemFn,
  openConfirmDeleteModal: (options: ConfirmModal.Options) => void,
  provided: DraggableProvided
}) {
  const addItemModal = useModal(EditItemModal)

  function handleClickAddItem(kind: Quiz.ItemKind) {
    addItemModal.open({
      title: 'Add Item',
      item: Quiz.createDefaultItem({ kind }),
      onSave: newItem => {
        addItemToSection(newItem, section)
      }
    })
  }

  return (
    // Stack of section header and items
    <Paper
      withBorder
      ref={provided.innerRef} // eslint-disable-line react-hooks/refs
      {...provided.draggableProps} // eslint-disable-line react-hooks/refs
      style={provided.draggableProps.style} // eslint-disable-line react-hooks/refs
    >
      <Stack gap={0} bg='dark.8'>
        {/* Section header */}
        <SectionHeader
          section={section}
          sectionIndex={sectionIndex}
          addSection={addSection}
          updateSection={updateSection}
          deleteSection={deleteSection}
          openConfirmDeleteModal={openConfirmDeleteModal}
          isExpanded={isExpanded}
          setExpanded={setExpanded}
          dragHandleProps={provided.dragHandleProps} // eslint-disable-line react-hooks/refs
        />
        {/*  */}
        {isExpanded && <Divider />}
        {/* Droppable of items */}
        {
          <Droppable
            droppableId={section.id}
            direction='vertical'
            type='row'
            renderClone={(provided, snapshot, rubric) => {
              return (
                <Paper
                  ref={provided.innerRef}
                  {...provided.draggableProps}
                  // bg='var(--mantine-color-gray-8)'
                  bg='dark.5'
                  h='4rem'
                  radius='sm'
                />
              )
            }}
          >
            {(provided) => (
              // Stack of rows and Add Item button
              <Stack
                ref={provided.innerRef}
                {...provided.droppableProps}
                gap='1.5rem'
                m='md'
                align='start'
                hidden={!isExpanded}
              >
                {section.rows.map((row, rowIndex) => (
                  // Draggable of row
                  <Draggable draggableId={row.itemId} index={rowIndex} key={row.itemId}>
                    {(provided) => (
                      // Row
                      <Box
                        ref={provided.innerRef}
                        {...provided.draggableProps}
                        style={{ ...provided.draggableProps.style }}
                        w='100%' // Important
                      // bg='var(--mantine-color-body)'
                      >
                        {(() => {
                          return (
                            <RowComponent
                              item={itemForId(row.itemId)!}
                              rowIndex={rowIndex}
                              addItem={addItem}
                              updateItem={updateItem}
                              deleteItem={deleteItem}
                              openConfirmDeleteModal={openConfirmDeleteModal}
                              dragHandleProps={provided.dragHandleProps}
                            />
                          )
                        })()}
                      </Box>
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
                <Menu offset={6} position='right-start'>
                  <Menu.Target>
                    <Button
                      variant='default' size='sm'
                      mt={section.rows.length > 0 ? '0.5rem' : 0}
                      leftSection={<IconPlus size={12} />}
                    >
                      Add Item
                    </Button>
                  </Menu.Target>
                  <Menu.Dropdown>
                    <AddItemMenuSection onAddItem={handleClickAddItem} />
                  </Menu.Dropdown>
                </Menu>
              </Stack>
            )}
          </Droppable>
        }
      </Stack>

      {/* Modals */}
      {addItemModal.element}
    </Paper>
  )
}

function SectionHeader({
  section, sectionIndex,
  addSection, updateSection, deleteSection,
  openConfirmDeleteModal,
  isExpanded, setExpanded,
  dragHandleProps
}: {
  section: Quiz.Section
  sectionIndex: number
  addSection: AddSectionFn
  updateSection: UpdateSectionFn
  deleteSection: DeleteSectionFn
  openConfirmDeleteModal: (options: ConfirmModal.Options) => void
  isExpanded: boolean
  setExpanded: (_: boolean) => void
  dragHandleProps: DraggableProvidedDragHandleProps | null
}) {
  const editSectionModal = useModal(EditSectionModal)

  const handleClickAdd = useCallback((position: 'before' | 'after') => {
    editSectionModal.open({
      title: 'Add Section',
      section: Quiz.createDefaultSection(),
      onSave: newSection => {
        addSection(newSection, section, position)
      }
    })
  }, [addSection, section, editSectionModal])

  const handleClickAddBefore = () => handleClickAdd('before')
  const handleClickAddAfter = () => handleClickAdd('after')

  const handleClickEdit = () => {
    editSectionModal.open({
      title: 'Edit Section',
      section: section,
      onSave: modified => {
        updateSection(modified)
      }
    })
  }

  const handleDelete = () => {
    openConfirmDeleteModal({
      title: <Text>Delete section <b>{section.name}</b>?</Text>,
      message: (
        <Stack gap='xs'>
          <Text>The section and its items will be deleted.</Text>
        </Stack>
      ),
      actions: [{
        label: 'Delete',
        role: 'destructive',
        handler: () => {
          deleteSection(section)
        }
      }]
    })
  }

  return (
    <Group bg='dark.6' wrap='nowrap' px='md' py='sm' align='flex-start'>
      {/* Expand button + name */}
      <Group gap='0' align='flex-start' wrap='nowrap' mr='auto'>
        {/* Expand button */}
        <ActionIcon
          variant='transparent'
          size='compact-md'
          onClick={() => setExpanded(!isExpanded)}
          color='gray'
          pl='0'
          pr='0.33rem'
          className='flex-none'
        >
          {isExpanded ?
            <IconChevronDown size={22} /> :
            <IconChevronRight size={22} />
          }
        </ActionIcon>
        {/* Name -- for some reason, Tailwind 'leading-' doesn't work here */}
        <Title order={4} style={{ lineHeight: '1.5rem' }}>
          {section.name}
        </Title>
      </Group>
      {/* Buttons */}
      <Group gap='xs' wrap='nowrap'>
        {/* Add Button */}
        <Menu offset={6} position='bottom-end' width={180}>
          <Menu.Target>
            <ActionIcon variant='subtle' size='md' color='gray'>
              <IconDots size={16} />
            </ActionIcon>
          </Menu.Target>
          <Menu.Dropdown>
            <Menu.Item leftSection={<IconPencil size={16} />} onClick={handleClickEdit}>Edit</Menu.Item>
            <Menu.Item leftSection={<IconTrash size={16} />} onClick={handleDelete}>Delete</Menu.Item>
            <Menu.Divider />
            <Menu.Label>Add Section</Menu.Label>
            <Menu.Item leftSection={<IconPlus size={16} />} onClick={handleClickAddBefore}>Add Above</Menu.Item>
            <Menu.Item leftSection={<IconPlus size={16} />} onClick={handleClickAddAfter}>Add Below</Menu.Item>
          </Menu.Dropdown>
        </Menu>
        <Box
          className='cursor-move'
          p='0.33rem'
          pr='0'
          {...dragHandleProps}
        >
          {/* Old: IconGripVertical */}
          <IconSelector size={16} />
        </Box>
      </Group>

      {/* Modals */}
      {editSectionModal.element}
    </Group>
  )
}

function RowComponent({
  item, rowIndex,
  addItem, updateItem, deleteItem,
  openConfirmDeleteModal,
  dragHandleProps
}: {
  item: Quiz.Item,
  rowIndex: number,
  addItem: AddItemFn,
  updateItem: UpdateItemFn,
  deleteItem: DeleteItemFn,
  openConfirmDeleteModal: (_: ConfirmModal.Options) => void,
  dragHandleProps: DraggableProvidedDragHandleProps | null,
}) {
  const editItemModal = useModal(EditItemModal)

  const handleClickAdd = useCallback((kind: Quiz.ItemKind) => {
    editItemModal.open({
      title: 'Add Item',
      item: Quiz.createDefaultItem({ kind }),
      onSave: newItem => {
        addItem(newItem, item)
      }
    })
  }, [item, addItem, editItemModal])

  const handleClickEdit = useCallback(() => {
    editItemModal.open({
      title: 'Edit Item',
      item,
      onSave: modifiedItem => {
        updateItem(modifiedItem)
      }
    })
  }, [item, updateItem, editItemModal])

  const handleClickDelete = useCallback(() => {
    openConfirmDeleteModal({
      title: <Text>Delete item?</Text>,
      message: null,
      actions: [{
        label: 'Delete',
        role: 'destructive',
        handler: () => {
          deleteItem(item)
        }
      }]
    })
  }, [item, deleteItem, openConfirmDeleteModal])

  const controlSection = useMemo(() => (
    <Group gap='xs' wrap='nowrap'>
      {/* Action Button */}
      <Menu offset={6} position='bottom-end'>
        <Menu.Target>
          <ActionIcon variant='subtle' size='md' color='gray'>
            <IconDots size={16} />
          </ActionIcon>
        </Menu.Target>
        <Menu.Dropdown>
          <Menu.Item leftSection={<IconPencil size={16} />} onClick={handleClickEdit}>Edit</Menu.Item>
          <Menu.Item leftSection={<IconTrash size={16} />} onClick={handleClickDelete}>Delete</Menu.Item>
          <Menu.Divider />
          <Menu.Label>Add Item</Menu.Label>
          <AddItemMenuSection onAddItem={handleClickAdd} />
        </Menu.Dropdown>
      </Menu>
      {/* Drag Handle */}
      <Box
        className='cursor-move'
        p='0.33rem'
        pr='0'
        {...dragHandleProps}
      >
        {/* Old icon: IconGripVertical */}
        <IconSelector size={16} />
      </Box>
    </Group>
  ), [dragHandleProps, handleClickAdd, handleClickDelete, handleClickEdit])

  return (
    <Group w='100%' gap='sm' wrap='nowrap' align='start'>
      {/* Index */}
      <Text fw='bold' w='1.2rem'>{rowIndex + 1}.</Text>
      {/* Item */}
      <ReadonlyItemComponent item={item} controlSection={controlSection} />

      {/* Modals */}
      {editItemModal.element}
    </Group>
  )
}

function AddItemMenuSection({ onAddItem }: {
  onAddItem: (kind: Quiz.ItemKind) => void
}) {
  return (
    <>
      <Menu.Item leftSection={<IconSquareCheck size={14} />}
        onClick={() => onAddItem('selectedResponseItem')}
      >
        Multiple Choice Item
      </Menu.Item>
      <Menu.Item
        leftSection={<IconSquareLetterT size={14} />}
        onClick={() => onAddItem('textInputItem')}
      >
        Text Item
      </Menu.Item>
      <Menu.Item
        leftSection={<IconListNumbers size={14} />}
        onClick={() => onAddItem('listItem')}
      >
        List Item
      </Menu.Item>
    </>
  )
}

type AddSectionFn = (section: Quiz.Section, anchor: Quiz.Section, position: 'before' | 'after') => void
type UpdateSectionFn = (section: Quiz.Section) => void
type DeleteSectionFn = (section: Quiz.Section) => void
type AddItemFn = (item: Quiz.Item, afterItem: Quiz.Item) => void
type AddItemToSectionFn = (item: Quiz.Item, section: Quiz.Section) => void
type UpdateItemFn = (item: Quiz.Item) => void
type DeleteItemFn = (item: Quiz.Item) => void