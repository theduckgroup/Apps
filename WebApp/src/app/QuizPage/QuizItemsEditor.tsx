import { useState } from 'react'
import { ActionIcon, Box, Button, Divider, Flex, Group, Menu, Paper, Space, Stack, Text, Title } from '@mantine/core'
import { ObjectId } from 'bson'
import { produce } from 'immer'

import { Quiz } from 'src/models/Quiz'
import EditItemModal, { EditItemModalOptions } from './EditItemModal'
import EditSectionModal, { EditSectionModalOptions } from './EditSectionModal'
import ConfirmDeleteModal, { ConfirmDeleteModalOptions } from './ConfirmDeleteModal'
import { DragDropContext, Draggable, DraggableProvided, DraggableProvidedDragHandleProps, Droppable, DropResult } from '@hello-pangea/dnd'
import { IconChevronDown, IconChevronRight, IconDots, IconGripVertical, IconListNumbers, IconPencil, IconPlus, IconSquareCheck, IconSquareLetterT, IconTrash } from '@tabler/icons-react'
import ReadonlyItemComponent from './ReadonlyItemComponent'
import useRepeatedModal from 'src/common/use-repeated-modal'

export default function QuizItemsEditor({ items, sections, onChange }: {
  items: Quiz.Item[],
  sections: Quiz.Section[],
  onChange: (items: Quiz.Item[], sections: Quiz.Section[]) => void
}) {
  const editSectionModal = useRepeatedModal()
  const [editSectionModalOptions, setEditSectionModalOptions] = useState<EditSectionModalOptions>(EditSectionModalOptions.empty)

  const editItemModal = useRepeatedModal()
  const [editItemModalOptions, setEditItemModalOptions] = useState<EditItemModalOptions | null>(null)

  const deleteModal = useRepeatedModal()
  const [deleteModalOptions, setDeleteModalOptions] = useState<ConfirmDeleteModalOptions>(ConfirmDeleteModalOptions.empty)

  // Can't hold this inside SectionComponent because it gets reset during drag/drop
  const [sectionCollapsedIDs, setCollapsedSectionIDs] = useState<Set<string>>(new Set())

  function handleAddSection(atSectionIndex: number) {
    setEditSectionModalOptions({
      title: 'Add Section',
      fields: { name: '' },
      onSave: fields => {
        const newSections = produce(sections, sections => {
          const newSection: Quiz.Section = {
            id: new ObjectId().toString(),
            name: fields.name,
            rows: []
          }

          sections.splice(atSectionIndex, 0, newSection)
        })

        onChange(items, newSections)
      }
    })

    editSectionModal.open()
  }

  function handleEditSection(section: Quiz.Section, sectionIndex: number) {
    setEditSectionModalOptions({
      title: 'Edit Section',
      fields: {
        name: section.name
      },
      onSave: fields => {
        const newSections = produce(sections, sections => {
          sections[sectionIndex].name = fields.name
        })

        onChange(items, newSections)
      }
    })

    editSectionModal.open()
  }

  function handleDeleteSection(section: Quiz.Section, sectionIndex: number) {
    setDeleteModalOptions({
      message: (
        <Stack gap='xs'>
          <Text>Delete section '{section.name}'?</Text>
          <Text fw='bold'>This will delete the section and all of its items. This cannot be undone.</Text>
        </Stack>
      ),
      onDelete: () => {
        const newSections = produce(sections, sections => {
          sections.splice(sectionIndex, 1)
        })

        onChange(items, newSections)
      }
    })

    deleteModal.open()
  }

  function handleAddItem(kind: Quiz.ItemKind, atRowIndex: number, section: Quiz.Section, sectionIndex: number) {
    setEditItemModalOptions({
      title: 'Add Item',
      item: Quiz.createDefaultItem(kind),
      onSave: item => {
        const newItems = [...items, item]

        const newSections = produce(sections, sections => {
          const newRow: Quiz.Row = {
            itemId: item.id
          }

          sections[sectionIndex].rows.splice(atRowIndex, 0, newRow)
        })

        onChange(newItems, newSections)
      }
    })

    editItemModal.open()
  }

  function handleEditItem(item: Quiz.Item, rowIndex: number, section: Quiz.Section, sectionIndex: number) {
    setEditItemModalOptions({
      title: 'Edit Item',
      item,
      onSave: item => {
        const newItems = produce(items, items => {
          const index = items.findIndex(x => x.id == item.id)
          items[index] = item
        })

        onChange(newItems, sections)
      }
    })

    editItemModal.open()
  }

  function handleDeleteItem(item: Quiz.Item, rowIndex: number, section: Quiz.Section, sectionIndex: number) {
    setDeleteModalOptions({
      message: (
        <Stack gap='xs'>
          <Text>Delete item '{item.id}'?</Text>
          <Text fw='bold'>This cannot be undone.</Text>
        </Stack>
      ),
      onDelete: () => {
        const newItems = produce(items, items => {
          const index = items.findIndex(x => x.id == item.id)!
          items.splice(index, 1)
        })

        const newSections = produce(sections, sections => {
          sections[sectionIndex].rows.splice(rowIndex, 1)
        })

        onChange(newItems, newSections)
      }
    })

    deleteModal.open()
  }

  function onDragEnd(result: DropResult) {
    const { destination, source, type } = result

    if (!destination) {
      return // Dragged outside of a droppable area
    }

    if (destination.droppableId === source.droppableId && destination.index === source.index) {
      return // Dropped at the same position
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

      onChange(items, newSections)

    } else if (type === 'section') {
      // Reordering sections

      const newSections = produce(sections, sections => {
        const [draggedSection] = sections.splice(source.index, 1)
        sections.splice(destination.index, 0, draggedSection)
      })

      onChange(items, newSections)
    }
  }

  function isSectionExpanded(sectionId: string) {
    return !sectionCollapsedIDs.has(sectionId)
  }

  function setSectionExpanded(sectionId: string, value: boolean) {
    const newValue = produce(sectionCollapsedIDs, set => {
      if (value) {
        set.delete(sectionId)
      } else {
        set.add(sectionId)
      }
    })

    setCollapsedSectionIDs(newValue)
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
                      handleAddSection={atIndex => handleAddSection(atIndex) }
                      handleEditSection={() => handleEditSection(section, sectionIndex) }
                      handleDeleteSection={() => handleDeleteSection(section, sectionIndex) }
                      handleAddItem={handleAddItem}
                      handleEditItem={handleEditItem}
                      handleDeleteItem={handleDeleteItem}
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
                onClick={() => handleAddSection(sections.length)}
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
      {editItemModal.modalIDs.map(id =>
        <EditItemModal key={id} opened={editItemModal.isOpened(id)} close={editItemModal.close} options={editItemModalOptions} />
      )}
      {deleteModal.modalIDs.map(id =>
        <ConfirmDeleteModal key={id} opened={deleteModal.isOpened(id)} close={deleteModal.close} options={deleteModalOptions} />
      )}
    </>
  )
}

function SectionComponent({
  section, sectionIndex, itemForId,
  isExpanded, onExpandedChange,
  handleAddSection, handleEditSection, handleDeleteSection,
  handleAddItem, handleEditItem, handleDeleteItem,
  provided
}: {
  section: Quiz.Section,
  sectionIndex: number,
  itemForId: (id: string) => Quiz.Item | undefined,
  isExpanded: boolean,
  onExpandedChange: (_: boolean) => void,
  handleAddSection: (atIndex: number) => void,
  handleEditSection: () => void,
  handleDeleteSection: () => void,
  handleAddItem: (kind: Quiz.ItemKind, rowIndex: number, section: Quiz.Section, sectionIndex: number) => void
  handleEditItem: (_: Quiz.Item, rowIndex: number, section: Quiz.Section, sectionIndex: number) => void
  handleDeleteItem: (_: Quiz.Item, rowIndex: number, section: Quiz.Section, sectionIndex: number) => void
  provided: DraggableProvided
}) {
  return (
    // Stack of section header and items
    <Paper
      withBorder
      ref={provided.innerRef}
      {...provided.draggableProps}
      style={provided.draggableProps.style}
    >
      <Stack
        gap={0}
        // bg='var(--mantine-color-body)'
        bg='dark.8'
      >
        {/* Section header */}
        <SectionHeader
          section={section}
          onEdit={() => handleEditSection(section, sectionIndex)}
          onDelete={() => handleDeleteSection(section, sectionIndex)}
          onAddItem={(kind) => handleAddItem(kind, section.rows.length, section, sectionIndex)}
          onAddSectionAbove={() => handleAddSection(sectionIndex)}
          onAddSectionBelow={() => handleAddSection(sectionIndex + 1)}
          isExpanded={isExpanded}
          onExpandedChange={onExpandedChange}
          dragHandleProps={provided.dragHandleProps}
        />
        {/*  */}
        {isExpanded && <Divider />}
        {/* Droppable of items */}
        {
          isExpanded &&
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
                gap='md'
                m='md'
                align='start'
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
                          const item = itemForId(row.itemId)

                          return (
                            <Row
                              item={itemForId(row.itemId)}
                              index={rowIndex}
                              onAddItem={kind => handleAddItem(kind, rowIndex + 1, section, sectionIndex)}
                              onEdit={() => handleEditItem(item!, rowIndex, section, sectionIndex)}
                              onDelete={() => handleDeleteItem(item!, rowIndex, section, sectionIndex)}
                              dragHandleProps={provided.dragHandleProps}
                            />
                          )
                        })()}
                      </Box>
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
                <Menu offset={6} position='right-end'>
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
                    <AddItemMenuSection onAddItem={kind => handleAddItem(kind, section.rows.length, section, sectionIndex)} />
                  </Menu.Dropdown>
                </Menu>
              </Stack>
            )}
          </Droppable>
        }
      </Stack>
    </Paper>
  )
}

function SectionHeader({ section, onEdit, onDelete, onAddItem, onAddSectionAbove, onAddSectionBelow, isExpanded, onExpandedChange, dragHandleProps }: {
  section: Quiz.Section
  onEdit: () => void,
  onDelete: () => void
  onAddItem: (kind: Quiz.ItemKind) => void
  onAddSectionAbove: () => void
  onAddSectionBelow: () => void
  isExpanded: boolean
  onExpandedChange: (_: boolean) => void
  dragHandleProps: DraggableProvidedDragHandleProps | null
}) {
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
        <Menu offset={6} position='bottom-end'>
          <Menu.Target>
            <ActionIcon variant='default' size='md' color='gray'>
              <IconDots size={16} />
            </ActionIcon>
          </Menu.Target>
          <Menu.Dropdown>
            <Menu.Item leftSection={<IconPencil size={16} />} onClick={onEdit}>Edit</Menu.Item>
            <Menu.Item leftSection={<IconTrash size={16} />} onClick={onDelete}>Delete</Menu.Item>
            <Menu.Divider />
            <Menu.Label>Add Item</Menu.Label>
            <AddItemMenuSection onAddItem={onAddItem} />
            <Menu.Divider />
            <Menu.Label>Add Section</Menu.Label>
            <Menu.Item leftSection={<IconPlus size={14} />} onClick={onAddSectionAbove}>Add Section Above</Menu.Item>
            <Menu.Item leftSection={<IconPlus size={14} />} onClick={onAddSectionBelow}>Add Section Below</Menu.Item>
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
    </Group>
  )
}

function Row({ item, index, onEdit, onDelete, onAddItem, dragHandleProps }: {
  item: Quiz.Item | undefined,
  index: number,
  onEdit: () => void,
  onDelete: () => void,
  onAddItem: (kind: Quiz.ItemKind) => void,
  dragHandleProps: DraggableProvidedDragHandleProps | null,
}) {
  const controlSection = (
    <Group gap='xs' wrap='nowrap'>
      {/* Action Button */}
      <Menu offset={6} position='bottom-end'>
        <Menu.Target>
          <ActionIcon variant='default' size='md' color='gray'>
            <IconDots size={16} />
          </ActionIcon>
          {/* <Button variant='default' size='compact-xs' color='gray'>
            Action
          </Button> */}
        </Menu.Target>
        <Menu.Dropdown>
          <Menu.Item leftSection={<IconPencil size={16} />} onClick={onEdit}>Edit</Menu.Item>
          <Menu.Item leftSection={<IconTrash size={16} />} onClick={onDelete}>Delete</Menu.Item>
          <Menu.Divider />
          <Menu.Label>Add Item</Menu.Label>
          <AddItemMenuSection onAddItem={onAddItem} />
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
  )

  return (
    <Group w='100%' gap='sm' wrap='nowrap' align='start'>
      <Text fz='sm' w='0.5rem'>{index + 1}.</Text>
      {
        item ? (
          <ReadonlyItemComponent item={item} controlSection={controlSection} />
        ) : (
          <Group mr='auto'>
            <Text>Item Not Found</Text>
            {controlSection}
          </Group>
        )
      }
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