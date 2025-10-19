import { useCallback, useMemo, useState } from 'react'
import { ActionIcon, Box, Button, Divider, Group, Menu, Paper, Stack, Text, Title } from '@mantine/core'
import { DragDropContext, Draggable, DraggableProvided, DraggableProvidedDragHandleProps, Droppable, DropResult } from '@hello-pangea/dnd'
import { IconChevronDown, IconChevronRight, IconDots, IconGripVertical, IconListNumbers, IconPencil, IconPlus, IconSquareCheck, IconSquareLetterT, IconTrash } from '@tabler/icons-react'
import { produce } from 'immer'

import { Quiz } from 'src/quiz-app/models/Quiz'
import EditItemModal, { EditItemModalOptions } from './EditItemModal'
import EditSectionModal, { EditSectionModalOptions } from './EditSectionModal'
import ConfirmDeleteModal, { ConfirmDeleteModalOptions } from './ConfirmDeleteModal'
import { ConfirmModal } from 'src/utils/ConfirmModal'
import ReadonlyItemComponent from './ReadonlyItemComponent'
import useRepeatedModal from 'src/utils/use-repeated-modal'
import { Dispatch, ReduceState } from 'src/utils/types-lib'
import useModal from 'src/utils/use-modal'

export default function QuizItemsEditor({ items, sections, setData }: {
  items: Quiz.Item[],
  sections: Quiz.Section[],
  setData: Dispatch<ReduceState<[Quiz.Item[], Quiz.Section[]]>>
}) {
  const editSectionModal = useRepeatedModal() // For adding section
  const [editSectionModalOptions, setEditSectionModalOptions] = useState<EditSectionModalOptions | null>(null)

  // Can't hold this inside SectionComponent because it gets reset during drag/drop
  const [collapsedSectionIDs, setCollapsedSectionIDs] = useState<Set<string>>(new Set())

  const handleAddSection: AddSectionHandler = (newSection, anchor, position) => {
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

  const handleEditSection: EditSectionHandler = (section) => {
    setData(([items, sections]) => {
      const newSections = [...sections]
      const sectionIndex = newSections.findIndex(x => x.id == section.id)!
      newSections[sectionIndex] = section

      return [items, newSections]
    })
  }

  const handleDeleteSection: DeleteSectionHandler = (section) => {
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

  const handleAddItem: AddItemHandler = (item, afterItem) => {
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

  const handleAddItemToSection: AddItemToSectionHandler = (item, section) => {
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

  const handleEditItem: EditItemHandler = (item) => {
    setData(([items, sections]) => {
      const newItems = produce(items, items => {
        const index = items.findIndex(x => x.id == item.id)
        items[index] = item
      })

      return [newItems, sections]
    })
  }

  const handleDeleteItem: EditItemHandler = (item) => {
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

      if (type === 'item') {
        // Reordering items within a section or moving between sections

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
    setEditSectionModalOptions({
      title: 'Add Section',
      section: Quiz.createDefaultSection(),
      onSave: newSection => {
        setData(([items, sections]) => {
          const newSections = [...sections, newSection]
          return [items, newSections]
        })
      }
    })

    editSectionModal.open()
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
                      onExpandedChange={value => setSectionExpanded(section.id, value)}
                      onAddSection={handleAddSection}
                      onEditSection={handleEditSection}
                      onDeleteSection={handleDeleteSection}
                      onAddItem={handleAddItem}
                      onAddItemToSection={handleAddItemToSection}
                      onEditItem={handleEditItem}
                      onDeleteItem={handleDeleteItem}
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
      {editSectionModal.modalIDs.map(id =>
        <EditSectionModal key={id} opened={editSectionModal.isOpened(id)} close={editSectionModal.close} options={editSectionModalOptions} />
      )}
    </>
  )
}

function SectionComponent({
  section, sectionIndex, itemForId,
  isExpanded, onExpandedChange,
  onAddSection, onEditSection, onDeleteSection,
  onAddItem, onAddItemToSection, onEditItem, onDeleteItem,
  provided
}: {
  section: Quiz.Section,
  sectionIndex: number,
  itemForId: (id: string) => Quiz.Item | undefined,
  isExpanded: boolean,
  onExpandedChange: (_: boolean) => void,
  onAddSection: AddSectionHandler,
  onEditSection: EditSectionHandler,
  onDeleteSection: DeleteSectionHandler,
  onAddItem: AddItemHandler,
  onAddItemToSection: AddItemToSectionHandler,
  onEditItem: EditItemHandler,
  onDeleteItem: EditItemHandler,
  provided: DraggableProvided
}) {
  const editItemModal = useRepeatedModal() // For 'Add Item' button
  const [editItemModalOptions, setEditItemModalOptions] = useState<EditItemModalOptions | null>(null)

  function handleClickAddItem(kind: Quiz.ItemKind) {
    setEditItemModalOptions({
      title: 'Add Item',
      item: Quiz.createDefaultItem(kind),
      onSave: newItem => {
        onAddItemToSection(newItem, section)
      }
    })

    editItemModal.open()
  }

  return (
    // Stack of section header and items
    <Paper
      withBorder
      ref={provided.innerRef}
      {...provided.draggableProps}
      style={provided.draggableProps.style}
    >
      <Stack gap={0} bg='dark.8'>
        {/* Section header */}
        <SectionHeader
          section={section}
          sectionIndex={sectionIndex}
          onAddSection={onAddSection}
          onEditSection={onEditSection}
          onDeleteSection={onDeleteSection}
          isExpanded={isExpanded}
          onExpandedChange={onExpandedChange}
          dragHandleProps={provided.dragHandleProps}
        />
        {/*  */}
        {isExpanded && <Divider />}
        {/* Droppable of items */}
        {
          // isExpanded &&
          <Droppable
            droppableId={section.id}
            direction='vertical'
            type='item'
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
              // Stack of rows/items and Add Item button
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
                            <Row
                              item={itemForId(row.itemId)!}
                              rowIndex={rowIndex}
                              onAddItem={onAddItem}
                              onEditItem={onEditItem}
                              onDeleteItem={onDeleteItem}
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
      {editItemModal.modalIDs.map(id =>
        <EditItemModal key={id} opened={editItemModal.isOpened(id)} close={editItemModal.close} options={editItemModalOptions} />
      )}
    </Paper>
  )
}

function SectionHeader({ section, sectionIndex, onAddSection, onEditSection, onDeleteSection, isExpanded, onExpandedChange, dragHandleProps }: {
  section: Quiz.Section
  sectionIndex: number,
  onAddSection: AddSectionHandler,
  onEditSection: EditSectionHandler,
  onDeleteSection: DeleteSectionHandler,
  isExpanded: boolean
  onExpandedChange: (_: boolean) => void
  dragHandleProps: DraggableProvidedDragHandleProps | null
}) {
  const editSectionModal = useRepeatedModal()
  const [editSectionModalOptions, setEditSectionModalOptions] = useState<EditSectionModalOptions | null>(null)

  // const confirmModal = useRepeatedModal()
  // const [deleteModalOptions, setDeleteModalOptions] = useState<ConfirmModal.Props | null>(null)
  const confirmModal = useModal<ConfirmModal.Options>(ConfirmModal)

  const handleClickAdd = useCallback((position: 'before' | 'after') => {
    setEditSectionModalOptions({
      title: 'Add Section',
      section: Quiz.createDefaultSection(),
      onSave: newSection => {
        onAddSection(newSection, section, position)
      }
    })

    editSectionModal.open()
  }, [onAddSection, section, editSectionModal])

  const handleClickAddBefore = () => handleClickAdd('before')
  const handleClickAddAfter = () => handleClickAdd('after')

  const handleClickEdit = () => {
    setEditSectionModalOptions({
      title: 'Edit Section',
      section: section,
      onSave: modified => {
        onEditSection(modified)
      }
    })

    editSectionModal.open()
  }

  // const handleDelete = () => {
  //   setDeleteModalOptions({
  //     title: 'Delete Section'
  //     message: (
  //       <Stack gap='xs'>
  //         <Text>Delete section '{section.name}'?</Text>
  //         <Text fw='bold'>This will delete the section and all of its items. This cannot be undone.</Text>
  //       </Stack>
  //     ),

  //     onDelete: () => {
  //       onDeleteSection(section)
  //     }
  //   })

  //   confirmModal.open()
  // }

  const handleDelete = () => {
    confirmModal.open({
      title: 'Delete',
      message: (
        <Stack gap='xs'>
          <Text>Delete section '{section.name}'?</Text>
          <Text fw='bold'>This will delete the section and all of its items. This cannot be undone.</Text>
        </Stack>
      ),
      actions: [
        {
          label: 'Delete',
          role: 'destructive',
          handler: () => {
            onDeleteSection(section)
          }
        }
      ]
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
          onClick={() => onExpandedChange(!isExpanded)}
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
            <ActionIcon variant='default' size='md' color='gray'>
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
        {/* Drag Handle */}
        {/* <ActionIcon
          variant='default'
          size='md'
          color='gray'
          {...dragHandleProps}
        > */}
        <Box
          className='cursor-move'
          p='0.33rem'
          pr='0'
          {...dragHandleProps}
        >
          <IconGripVertical size={16} />
          {/* <IconMenuOrder />
            <IconArrowsMoveVertical />
            <IconArrowsSort />
            <IconBaselineDensityMedium /> 
            <IconMenu size={21} strokeWidth={1.75} /> */}
        </Box>
        {/* </ActionIcon> */}
        {/* </Button.Group> */}
      </Group>

      {/* Modals */}
      {editSectionModal.modalIDs.map(id =>
        <EditSectionModal key={id} opened={editSectionModal.isOpened(id)} close={editSectionModal.close} options={editSectionModalOptions} />
      )}
      {/* {confirmModal.modalIDs.map(id =>
        <ConfirmModal key={id} opened={confirmModal.isOpened(id)} close={confirmModal.close} options={deleteModalOptions} />
      )} */}
      {confirmModal.element}
    </Group>
  )
}

function Row({ item, rowIndex, onAddItem, onEditItem, onDeleteItem, dragHandleProps }: {
  item: Quiz.Item,
  rowIndex: number,
  onAddItem: AddItemHandler,
  onEditItem: EditItemHandler,
  onDeleteItem: DeleteItemHandler,
  dragHandleProps: DraggableProvidedDragHandleProps | null,
}) {
  const editItemModal = useRepeatedModal()
  const [editItemModalOptions, setEditItemModalOptions] = useState<EditItemModalOptions | null>(null)

  // const confirmModal = useRepeatedModal()
  // const [confirmModalOptions, setConfirmModalOptions] = useState<ConfirmModal.Options | null>(null)
  // const deleteModal = useRepeatedModal()
  // const [deleteModalOptions, setDeleteModalOptions] = useState<ConfirmDeleteModalOptions | null>(null)
  const confirmModal = useModal(ConfirmModal)

  const handleClickAdd = useCallback((kind: Quiz.ItemKind) => {
    setEditItemModalOptions({
      title: 'Add Item',
      item: Quiz.createDefaultItem(kind),
      onSave: newItem => {
        onAddItem(newItem, item)
      }
    })

    editItemModal.open()
  }, [item, onAddItem, editItemModal])

  const handleClickEdit = useCallback(() => {
    setEditItemModalOptions({
      title: 'Edit Item',
      item,
      onSave: modifiedItem => {
        onEditItem(modifiedItem)
      }
    })

    editItemModal.open()
  }, [item, onEditItem, editItemModal])

  // const handleClickDelete = useCallback(() => {
  //   setConfirmModalOptions({
  //     message: (
  //       <Stack gap='xs'>
  //         <Text>Delete item '{item.data.prompt}'?</Text>
  //         <Text fw='bold'>This cannot be undone.</Text>
  //       </Stack>
  //     ),
  //     onDelete: () => {
  //       onDeleteItem(item)
  //     }
  //   })

  //   confirmModal.open()
  // }, [item, onDeleteItem, confirmModal])

  // const handleClickDelete = useCallback(() => {
  //   setDeleteModalOptions({

  //     message: (
  //       <Stack gap='xs'>
  //         <Text>Delete item '{item.data.prompt}'?</Text>
  //         <Text fw='bold'>This cannot be undone.</Text>
  //       </Stack>
  //     ),
  //     onDelete: () => {
  //       onDeleteItem(item)
  //     }
  //   })

  //   deleteModal.open()
  // }, [item, onDeleteItem, deleteModal])

  const handleClickDelete = useCallback(() => {
    confirmModal.open({
      title: 'Delete Item',
      message: (
        <Stack gap='xs'>
          <Text>Delete item '{item.data.prompt}'?</Text>
          <Text fw='bold'>This cannot be undone.</Text>
        </Stack>
      ),
      actions: [
        {
          label: 'Delete',
          role: 'destructive',
          handler: () => {
            onDeleteItem(item)
          }
        }
      ]
    })
  }, [item, onDeleteItem, confirmModal])

  const controlSection = useMemo(() => (
    <Group gap='xs' wrap='nowrap'>
      {/* Action Button */}
      <Menu offset={6} position='bottom-end'>
        <Menu.Target>
          <ActionIcon variant='default' size='md' color='gray'>
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
        <IconGripVertical size={16} />
      </Box>
      {/* <ActionIcon
        variant='default'
        size='md'
        color='gray'
        {...dragHandleProps}
      >
        <IconGripVertical size={16} />
      </ActionIcon> */}
    </Group>
  ), [dragHandleProps, handleClickAdd, handleClickDelete, handleClickEdit])

  return (
    <Group w='100%' gap='sm' wrap='nowrap' align='start'>
      {/* Index */}
      <Text fw='bold' w='1.2rem'>{rowIndex + 1}.</Text>
      {/* Item */}
      <ReadonlyItemComponent item={item} controlSection={controlSection} />

      {/* Modals */}
      {editItemModal.modalIDs.map(id =>
        <EditItemModal key={id} opened={editItemModal.isOpened(id)} close={editItemModal.close} options={editItemModalOptions} />
      )}
      {/* {confirmModal.modalIDs.map(id =>
        <ConfirmDeleteModal key={id} opened={confirmModal.isOpened(id)} close={confirmModal.close} options={confirmModalOptions} />
      )} */}
      {/* {deleteModal.modalIDs.map(id =>
        <ConfirmDeleteModal key={id} opened={deleteModal.isOpened(id)} close={deleteModal.close} options={deleteModalOptions} />
      )} */}
      {confirmModal.element}
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

type AddSectionHandler = (section: Quiz.Section, anchor: Quiz.Section, position: 'before' | 'after') => void
type EditSectionHandler = (section: Quiz.Section) => void
type DeleteSectionHandler = (section: Quiz.Section) => void
type AddItemHandler = (item: Quiz.Item, afterItem: Quiz.Item) => void
type AddItemToSectionHandler = (item: Quiz.Item, section: Quiz.Section) => void
type EditItemHandler = (item: Quiz.Item) => void
type DeleteItemHandler = (item: Quiz.Item) => void