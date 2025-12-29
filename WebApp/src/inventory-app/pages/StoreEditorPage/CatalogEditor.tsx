import { useCallback, useState } from 'react'
import { produce } from 'immer'
import { ActionIcon, Box, Button, Divider, Group, Menu, Paper, Stack, Text, Title } from '@mantine/core'
import { DragDropContext, Draggable, DraggableProvided, DraggableProvidedDragHandleProps, Droppable, DropResult } from '@hello-pangea/dnd'

import { InvStore } from 'src/inventory-app/models/InvStore'
import { EditSectionModal } from './EditSectionModal'
import { EditItemModal } from './EditItemModal'
import { ConfirmModal } from 'src/utils/ConfirmModal'
import useModal from 'src/utils/use-modal'
import { IconChevronDown, IconChevronRight, IconDots, IconPencil, IconPlus, IconSelector, IconTrash } from '@tabler/icons-react'
import { Dispatch, Reducer } from 'src/utils/types-lib'

export function CatalogEditor({ items, sections, setData }: {
  items: InvStore.Item[],
  sections: InvStore.Section[],
  setData: Dispatch<Reducer<[InvStore.Item[], InvStore.Section[]]>>,
}) {
  const editSectionModal = useModal(EditSectionModal)
  const editItemModal = useModal(EditItemModal)
  const confirmDeleteModal = useModal(ConfirmModal)

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

  const editSection: EditSectionFn = (section) => {
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
        const newRow: InvStore.Row = {
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
        const newRow: InvStore.Row = {
          itemId: item.id
        }

        const anchorSection = sections.find(x => x.id == section.id)!
        anchorSection.rows.push(newRow)
      })

      return [newItems, newSections]
    })
  }

  const editItem: EditItemFn = (item) => {
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

  const validateItemCode: ValidateItemCodeFn = useCallback((code, owner) => {
    const dup = items.find(x => x.id != owner?.id && x.code.trim() == code.trim())
    return dup ? `Code '${code}' is already used by item '${dup.name}'` : null
  }, [items])

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
      section: InvStore.newSection(),
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
              className='gap-2'
            >
              {sections.map((section, sectionIndex) => (
                // One section
                <Draggable draggableId={section.id} index={sectionIndex} key={section.id}>
                  {provided => (
                    <SectionComponent
                      section={section}
                      sectionIndex={sectionIndex}
                      itemForId={id => items.find(x => x.id == id)}
                      isExpanded={isSectionExpanded(section.id)}
                      setExpanded={value => setSectionExpanded(section.id, value)}
                      addSection={addSection}
                      editSection={editSection}
                      deleteSection={deleteSection}
                      addItem={addItem}
                      addItemToSection={addItemToSection}
                      editItem={editItem}
                      deleteItem={deleteItem}
                      validateItemCode={validateItemCode}
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
      {editItemModal.element}
      {confirmDeleteModal.element}
    </>
  )
}

function SectionComponent({
  section, sectionIndex, itemForId,
  isExpanded, setExpanded,
  addSection, editSection, deleteSection,
  addItem, addItemToSection, editItem, deleteItem,
  validateItemCode,
  openConfirmDeleteModal,
  provided
}: {
  section: InvStore.Section,
  sectionIndex: number,
  itemForId: (id: string) => InvStore.Item | undefined,
  isExpanded: boolean,
  setExpanded: (_: boolean) => void,
  addSection: AddSectionFn,
  editSection: EditSectionFn,
  deleteSection: DeleteSectionFn,
  addItem: AddItemFn,
  addItemToSection: AddItemToSectionFn,
  editItem: EditItemFn,
  deleteItem: EditItemFn,
  validateItemCode: ValidateItemCodeFn,
  openConfirmDeleteModal: (_: ConfirmModal.Options) => void,
  provided: DraggableProvided
}) {
  const addItemModal = useModal(EditItemModal)

  function handleClickAddItem() {
    addItemModal.open({
      title: 'Add Item',
      item: InvStore.newItem(),
      validateCode: validateItemCode,
      onSave: newItem => {
        addItemToSection(newItem, section)
      }
    })
  }

  return (
    // Stack of section header and items
    <Stack
      ref={provided.innerRef} // eslint-disable-line react-hooks/refs
      {...provided.draggableProps} // eslint-disable-line react-hooks/refs
      style={provided.draggableProps.style} // eslint-disable-line react-hooks/refs
      gap={0}
      className='w-full'
    // bg='var(--mantine-color-body)'
    >
      {/* Section header */}
      <SectionHeader
        section={section}
        sectionIndex={sectionIndex}
        addSection={addSection}
        editSection={editSection}
        deleteSection={deleteSection}
        openConfirmDeleteModal={openConfirmDeleteModal}
        isExpanded={isExpanded}
        setExpanded={setExpanded}
        dragHandleProps={provided.dragHandleProps} // eslint-disable-line react-hooks/refs
      />
      {/* <Divider /> */}
      {
        // Droppable of items
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
                className='h-4 rounded-sm'
              />
            )
          }}
        >
          {(provided) => (
            // Stack of rows and Add Item button
            <Stack
              ref={provided.innerRef}
              {...provided.droppableProps}
              gap={0}
              align='start'
              className='w-full'
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
                      className='w-full'
                    >
                      <RowComponent
                        item={itemForId(row.itemId)!}
                        rowIndex={rowIndex}
                        addItem={addItem}
                        editItem={editItem}
                        deleteItem={deleteItem}
                        validateItemCode={validateItemCode}
                        openConfirmDeleteModal={openConfirmDeleteModal}
                        dragHandleProps={provided.dragHandleProps}
                      />
                    </Box>
                  )}
                </Draggable>
              ))}
              {provided.placeholder}
              {
                // section.rows.length == 0 &&
                // Styling is same as RowComponent
                // border-b-1 border-b-neutral-700
                <Group className='w-full pl-4 pr-2 py-2 '>
                  <Button
                    variant='default'
                    size='sm'
                    leftSection={<IconPlus size={12} />}
                    my='sm'
                    ml=''
                    onClick={() => handleClickAddItem()}
                  >
                    Add Item
                  </Button>
                </Group>
              }
            </Stack>
          )}
        </Droppable>
      }

      {/* Modals */}
      {addItemModal.element}
    </Stack>
  )
}

function SectionHeader({ section, sectionIndex, addSection, editSection, deleteSection, openConfirmDeleteModal: openConfirmDeleteModal, isExpanded, setExpanded, dragHandleProps }: {
  section: InvStore.Section
  sectionIndex: number
  addSection: AddSectionFn
  editSection: EditSectionFn
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
      section: InvStore.newSection(),
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
        editSection(modified)
      }
    })
  }

  const handleDelete = () => {
    openConfirmDeleteModal({
      title: <Text>Delete section?</Text>,
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
    <Group
      bg='dark.7'
      // neutral
      className='w-full text-neutral-300 items-start flex-nowrap pl-4 pr-4 py-2 rounded-md'
    >
      {/* borderBottom: '1px solid var(--mantine-color-dark-4)' */}
      {/* <Group bg='dark.6' wrap='nowrap' px='md' py='sm' align='flex-start'> */}
      {/* Expand button + name */}
      <Group gap='0' align='center' wrap='nowrap' mr='auto'>
        {/* Expand button */}
        <ActionIcon
          variant='transparent'
          size='compact-md'
          onClick={() => setExpanded(!isExpanded)}
          className='flex-none'
          color='gray'
          pl='0'
          pr='0.5rem'
        >
          {isExpanded ?
            <IconChevronDown size={24} /> :
            <IconChevronRight size={24} />
          }
        </ActionIcon>
        {/* Name -- for some reason, Tailwind 'leading-' doesn't work here */}
        <div className='text-xl/relaxed font-bold'>
          {section.name}
        </div>
      </Group>
      {/* Buttons */}
      <Group gap='xs' wrap='nowrap'>
        {/* Add Button */}
        <Menu offset={6} position='bottom-end' width={210}>
          <Menu.Target>
            <ActionIcon variant='subtle' size='md' color='gray'>
              <IconDots size={16} />
            </ActionIcon>
          </Menu.Target>
          <Menu.Dropdown>
            <Menu.Item leftSection={<IconPencil size={16} />} onClick={handleClickEdit}>Edit</Menu.Item>
            <Menu.Item leftSection={<IconTrash size={16} />} onClick={handleDelete}>Delete</Menu.Item>
            <Menu.Divider />
            {/* <Menu.Label>Add Section</Menu.Label> */}
            <Menu.Item leftSection={<IconPlus size={16} />} onClick={handleClickAddBefore}>Add Section Above</Menu.Item>
            <Menu.Item leftSection={<IconPlus size={16} />} onClick={handleClickAddAfter}>Add Section Below</Menu.Item>
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

function RowComponent({ item, rowIndex, addItem, editItem, deleteItem, validateItemCode, openConfirmDeleteModal, dragHandleProps }: {
  item: InvStore.Item,
  rowIndex: number
  addItem: AddItemFn
  editItem: EditItemFn
  deleteItem: DeleteItemFn
  validateItemCode: ValidateItemCodeFn
  openConfirmDeleteModal: (_: ConfirmModal.Options) => void
  dragHandleProps: DraggableProvidedDragHandleProps | null
}) {
  const editItemModal = useModal(EditItemModal)

  const handleClickAdd = () => {
    editItemModal.open({
      title: 'Add Item',
      item: InvStore.newItem(),
      validateCode: validateItemCode,
      onSave: newItem => {
        addItem(newItem, item)
      }
    })
  }

  const handleClickEdit = () => {
    editItemModal.open({
      title: 'Edit Item',
      item,
      validateCode: validateItemCode,
      onSave: editItem
    })
  }

  const handleClickDelete = () => {
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
  }

  return (
    <Group
      className='w-full flex-nowrap items-start pl-4 pr-4 py-4 border-b-1 border-b-neutral-700'
      gap='md'
    >
      {/* Item name + code */}
      <Stack mr='auto' gap='0.25rem' align='start'>
        <Text>{item.name} ({item.code})</Text>
      </Stack>

      {/* Control section (action button, drag handle) */}
      <Group gap='xs' wrap='nowrap'>
        {/* Action Button */}
        <Menu offset={6} position='bottom-end' width={180}>
          <Menu.Target>
            <ActionIcon variant='subtle' size='md' color='gray'>
              <IconDots size={16} />
            </ActionIcon>
          </Menu.Target>
          <Menu.Dropdown>
            <Menu.Item leftSection={<IconPencil size={16} />} onClick={handleClickEdit}>Edit</Menu.Item>
            <Menu.Item leftSection={<IconTrash size={16} />} onClick={handleClickDelete}>Delete</Menu.Item>
            <Menu.Divider />
            <Menu.Item leftSection={<IconPlus size={16} />} onClick={handleClickAdd}>Add Item</Menu.Item>
          </Menu.Dropdown>
        </Menu>
        {/* Drag Handle */}
        <Box
          className='cursor-move'
          p='0.33rem'
          pr='0'
          {...dragHandleProps}
        >
          <IconSelector size={16} />
        </Box>
      </Group>

      {/* Modals */}
      {editItemModal.element}
    </Group>
  )
}

type AddSectionFn = (section: InvStore.Section, anchor: InvStore.Section, position: 'before' | 'after') => void
type EditSectionFn = (section: InvStore.Section) => void
type DeleteSectionFn = (section: InvStore.Section) => void
type AddItemFn = (item: InvStore.Item, afterItem: InvStore.Item) => void
type AddItemToSectionFn = (item: InvStore.Item, section: InvStore.Section) => void
type EditItemFn = (item: InvStore.Item) => void
type DeleteItemFn = (item: InvStore.Item) => void
type ValidateItemCodeFn = (code: string, owner: InvStore.Item | null) => string | null