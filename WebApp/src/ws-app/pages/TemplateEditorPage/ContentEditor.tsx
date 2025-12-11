import { useCallback, useState } from 'react'
import { ActionIcon, Box, Button, Divider, Group, Menu, Paper, Stack, Text, Title } from '@mantine/core'
import { DragDropContext, Draggable, DraggableProvided, DraggableProvidedDragHandleProps, Droppable, DropResult } from '@hello-pangea/dnd'
import { IconChevronDown, IconChevronRight, IconDots, IconPencil, IconPlus, IconSelector, IconTrash } from '@tabler/icons-react'
import { produce } from 'immer'

import { WsTemplate } from 'src/ws-app/models/WsTemplate'
import { EditSupplierModal } from './EditSupplierModal'
import { EditSectionModal } from './EditSectionModal'
import { ConfirmModal } from 'src/utils/ConfirmModal'
import { Dispatch, ReduceState } from 'src/utils/types-lib'
import useModal from 'src/utils/use-modal'

export function ContentEditor({ suppliers, sections, setData }: {
  suppliers: WsTemplate.Supplier[],
  sections: WsTemplate.Section[],
  setData: Dispatch<ReduceState<[WsTemplate.Supplier[], WsTemplate.Section[]]>>
}) {
  const editSectionModal = useModal(EditSectionModal)

  // Can't hold this inside SectionHeader or Row because they will be deleted
  const confirmDeleteModal = useModal(ConfirmModal)

  // Can't hold this inside SectionComponent because it gets reset during drag/drop
  const [collapsedSectionIDs, setCollapsedSectionIDs] = useState<Set<string>>(new Set())

  const handleAddSection: AddSectionHandler = (newSection, anchor, position) => {
    setData(([suppliers, sections]) => {
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

      return [suppliers, newSections]
    })
  }

  const handleEditSection: EditSectionHandler = (section) => {
    setData(([suppliers, sections]) => {
      const newSections = [...sections]
      const sectionIndex = newSections.findIndex(x => x.id == section.id)!
      newSections[sectionIndex] = section

      return [suppliers, newSections]
    })
  }

  const handleDeleteSection: DeleteSectionHandler = (section) => {
    setData(([suppliers, sections]) => {
      const newSections = [...sections]
      const sectionIndex = newSections.findIndex(x => x.id == section.id)!
      newSections.splice(sectionIndex, 1)

      // Delete suppliers in section
      const sectionSupplierIDs = new Set(section.rows.map(x => x.supplierId))
      const newSuppliers = suppliers.filter(x => !sectionSupplierIDs.has(x.id))

      return [newSuppliers, newSections]
    })

  }

  const handleAddSupplier: AddSupplierHandler = (supplier, afterSupplier) => {
    setData(([suppliers, sections]) => {
      const newSuppliers = [...suppliers, supplier]

      const newSections = produce(sections, sections => {
        const newRow: WsTemplate.Row = {
          supplierId: supplier.id
        }

        for (const section of sections) {
          const rowIndex = section.rows.findIndex(x => x.supplierId == afterSupplier.id)

          if (rowIndex >= 0) {
            section.rows.splice(rowIndex + 1, 0, newRow)
          }
        }
      })

      return [newSuppliers, newSections]
    })
  }

  const handleAddSupplierToSection: AddSupplierToSectionHandler = (supplier, section) => {
    setData(([suppliers, sections]) => {
      const newSuppliers = [...suppliers, supplier]

      const newSections = produce(sections, sections => {
        const newRow: WsTemplate.Row = {
          supplierId: supplier.id
        }

        const anchorSection = sections.find(x => x.id == section.id)!
        anchorSection.rows.push(newRow)
      })

      return [newSuppliers, newSections]
    })
  }

  const handleEditSupplier: EditSupplierHandler = (supplier) => {
    setData(([suppliers, sections]) => {
      const newSuppliers = produce(suppliers, suppliers => {
        const index = suppliers.findIndex(x => x.id == supplier.id)
        suppliers[index] = supplier
      })

      return [newSuppliers, sections]
    })
  }

  const handleDeleteSupplier: DeleteSupplierHandler = (supplier) => {
    setData(([suppliers, sections]) => {
      const newSuppliers = produce(suppliers, suppliers => {
        const index = suppliers.findIndex(x => x.id == supplier.id)!
        suppliers.splice(index, 1)
      })

      const newSections = produce(sections, sections => {
        for (const section of sections) {
          const rowIndex = section.rows.findIndex(x => x.supplierId == supplier.id)

          if (rowIndex != -1) {
            section.rows.splice(rowIndex, 1)
          }
        }
      })

      return [newSuppliers, newSections]
    })
  }

  const onDragEnd = (result: DropResult) => {
    setData(([suppliers, sections]) => {
      const { destination, source, type } = result

      if (!destination) {
        return [suppliers, sections] // Dragged outside of a droppable area
      }

      if (destination.droppableId === source.droppableId && destination.index === source.index) {
        return [suppliers, sections] // Dropped at the same position
      }

      if (type === 'row') {
        // Reordering rows within a section or moving between sections

        const sourceSectionId = source.droppableId
        const destinationSectionId = destination.droppableId

        const sourceSectionIndex = sections.findIndex(section => section.id === sourceSectionId)
        const destinationSectionIndex = sections.findIndex(section => section.id === destinationSectionId)

        const newSections = produce(sections, sections => {
          const [draggedRow] = sections[sourceSectionIndex].rows.splice(source.index, 1)
          sections[destinationSectionIndex].rows.splice(destination.index, 0, draggedRow)
        })

        return [suppliers, newSections]

      } else if (type === 'section') {
        // Reordering sections

        const newSections = produce(sections, sections => {
          const [draggedSection] = sections.splice(source.index, 1)
          sections.splice(destination.index, 0, draggedSection)
        })

        return [suppliers, newSections]

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
      section: WsTemplate.createDefaultSection(),
      onSave: newSection => {
        setData(([suppliers, sections]) => {
          const newSections = [...sections, newSection]
          return [suppliers, newSections]
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
            <Paper
              withBorder
            >
              <Stack
                {...provided.droppableProps}
                ref={provided.innerRef}
                // gap='md'
                gap='0px'
              >
                {sections.map((section, sectionIndex) => (
                  // One section
                  <Draggable key={section.id} draggableId={section.id} index={sectionIndex}>
                    {provided => (
                      <SectionComponent
                        section={section}
                        sectionIndex={sectionIndex}
                        itemForId={id => suppliers.find(x => x.id == id)}
                        isExpanded={isSectionExpanded(section.id)}
                        onExpandedChange={value => setSectionExpanded(section.id, value)}
                        onAddSection={handleAddSection}
                        onEditSection={handleEditSection}
                        onDeleteSection={handleDeleteSection}
                        onAddItem={handleAddSupplier}
                        onAddItemToSection={handleAddSupplierToSection}
                        onEditItem={handleEditSupplier}
                        onDeleteItem={handleDeleteSupplier}
                        onOpenConfirmDeleteModal={confirmDeleteModal.open}
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
                  m='md'
                  leftSection={<IconPlus size={13} />}
                  onClick={handleClickAddSection}
                >
                  Add Section
                </Button>
              </Stack>
            </Paper>
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
  section, sectionIndex, itemForId: supplierForId,
  isExpanded, onExpandedChange,
  onAddSection, onEditSection, onDeleteSection,
  onAddItem: onAddSupplier, onAddItemToSection, onEditItem: onEditSupplier, onDeleteItem: onDeleteSupplier,
  onOpenConfirmDeleteModal,
  provided
}: {
  section: WsTemplate.Section,
  sectionIndex: number,
  itemForId: (id: string) => WsTemplate.Supplier | undefined,
  isExpanded: boolean,
  onExpandedChange: (_: boolean) => void,
  onAddSection: AddSectionHandler,
  onEditSection: EditSectionHandler,
  onDeleteSection: DeleteSectionHandler,
  onAddItem: AddSupplierHandler,
  onAddItemToSection: AddSupplierToSectionHandler,
  onEditItem: EditSupplierHandler,
  onDeleteItem: EditSupplierHandler,
  onOpenConfirmDeleteModal: (options: ConfirmModal.Options) => void,
  provided: DraggableProvided
}) {
  const addSupplierModal = useModal(EditSupplierModal)
  // const [editItemModalOptions, setEditItemModalOptions] = useState<EditItemModalOptions | null>(null)

  function handleClickAddSupplier() {
    addSupplierModal.open({
      title: 'Add Suplier',
      supplier: WsTemplate.createDefaultSupplier(),
      onSave: newSupplier => {
        onAddItemToSection(newSupplier, section)
      }
    })
  }

  return (
    // Stack of section header and items
    // <Paper
    //   withBorder
    //   ref={provided.innerRef}
    //   {...provided.draggableProps}
    //   style={provided.draggableProps.style}
    // >
    <Stack
      gap={0}
      bg='dark.8'
      ref={provided.innerRef}
      {...provided.draggableProps}
      style={provided.draggableProps.style}
    >
      {/* Section header */}
      <SectionHeader
        section={section}
        sectionIndex={sectionIndex}
        onAddSection={onAddSection}
        onEditSection={onEditSection}
        onDeleteSection={onDeleteSection}
        onOpenConfirmDeleteModal={onOpenConfirmDeleteModal}
        isExpanded={isExpanded}
        onExpandedChange={onExpandedChange}
        dragHandleProps={provided.dragHandleProps}
      />
      {/*  */}
      {/* {isExpanded && <Divider />} */}
      {/* Droppable of rows */}
      {
        // isExpanded &&
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
            // Stack of rows and Add Supplier button
            <Stack
              ref={provided.innerRef}
              {...provided.droppableProps}
              // gap='1.5rem'
              gap='0px'
              // m='md'
              align='start'
              hidden={!isExpanded}
            >
              {section.rows.map((row, rowIndex) => (
                // Draggable of row
                <Draggable draggableId={row.supplierId} index={rowIndex} key={row.supplierId}>
                  {(provided) => (
                    // Row
                    <Box
                      ref={provided.innerRef}
                      {...provided.draggableProps}
                      style={{ ...provided.draggableProps.style }}
                      // className='border-b border-zinc-600'
                      w='100%' // Important
                    // bg='var(--mantine-color-body)'
                    >
                      {(() => {
                        return (
                          <>
                            <Row
                              supplier={supplierForId(row.supplierId)!}
                              rowIndex={rowIndex}
                              onAddSupplier={onAddSupplier}
                              onEditSupplier={onEditSupplier}
                              onDeleteSupplier={onDeleteSupplier}
                              onOpenConfirmDeleteModal={onOpenConfirmDeleteModal}
                              dragHandleProps={provided.dragHandleProps}
                            />
                            {rowIndex < section.rows.length - 1 && <Divider />}
                          </>
                        )
                      })()}
                    </Box>
                  )}
                </Draggable>
              ))}
              {provided.placeholder}
              {section.rows.length == 0 &&
                <Button
                  variant='default' size='sm'
                  // color='dark.1'
                  // mt={section.rows.length > 0 ? '0.5rem' : 0}
                  m='md'
                  leftSection={<IconPlus size={12} />}
                  onClick={handleClickAddSupplier}
                >
                  Add Supplier
                </Button>
              }
            </Stack>
          )}
        </Droppable>
      }
      {/* Modals */}
      {addSupplierModal.element}
    </Stack>

    // </Paper>
  )
}

function SectionHeader({ section, sectionIndex, onAddSection, onEditSection, onDeleteSection, onOpenConfirmDeleteModal, isExpanded, onExpandedChange, dragHandleProps }: {
  section: WsTemplate.Section
  sectionIndex: number,
  onAddSection: AddSectionHandler,
  onEditSection: EditSectionHandler,
  onDeleteSection: DeleteSectionHandler,
  onOpenConfirmDeleteModal: (options: ConfirmModal.Options) => void,
  isExpanded: boolean
  onExpandedChange: (_: boolean) => void
  dragHandleProps: DraggableProvidedDragHandleProps | null
}) {
  const editSectionModal = useModal(EditSectionModal)

  const handleClickAdd = useCallback((position: 'before' | 'after') => {
    editSectionModal.open({
      title: 'Add Section',
      section: WsTemplate.createDefaultSection(),
      onSave: newSection => {
        onAddSection(newSection, section, position)
      }
    })
  }, [onAddSection, section, editSectionModal])

  const handleClickAddBefore = () => handleClickAdd('before')
  const handleClickAddAfter = () => handleClickAdd('after')

  const handleClickEdit = () => {
    editSectionModal.open({
      title: 'Edit Section',
      section: section,
      onSave: modified => {
        onEditSection(modified)
      }
    })
  }

  const handleDelete = () => {
    onOpenConfirmDeleteModal({
      title: '',
      message: (
        <Stack gap='xs'>
          <Text>Delete section '{section.name}'?</Text>
          <Text fw='bold'>This will delete the section and its suppliers. This cannot be undone.</Text>
        </Stack>
      ),
      actions: [{
        label: 'Delete',
        role: 'destructive',
        handler: () => {
          onDeleteSection(section)
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
          <IconSelector size={16} />
        </Box>
      </Group>

      {/* Modals */}
      {editSectionModal.element}
    </Group>
  )
}

function Row({ supplier, rowIndex, onAddSupplier, onEditSupplier, onDeleteSupplier, onOpenConfirmDeleteModal, dragHandleProps }: {
  supplier: WsTemplate.Supplier,
  rowIndex: number,
  onAddSupplier: AddSupplierHandler,
  onEditSupplier: EditSupplierHandler,
  onDeleteSupplier: DeleteSupplierHandler,
  onOpenConfirmDeleteModal: (options: ConfirmModal.Options) => void,
  dragHandleProps: DraggableProvidedDragHandleProps | null,
}) {
  const editModal = useModal(EditSupplierModal)

  const handleClickAdd = () => {
    editModal.open({
      title: 'Add Supplier',
      supplier: WsTemplate.createDefaultSupplier(),
      onSave: newSupplier => {
        onAddSupplier(newSupplier, /* after */ supplier)
      }
    })
  }

  const handleClickEdit = () => {
    editModal.open({
      title: 'Edit Supplier',
      supplier,
      onSave: modifiedSupplier => {
        onEditSupplier(modifiedSupplier)
      }
    })
  }

  const handleClickDelete = () => {
    onOpenConfirmDeleteModal({
      title: '',
      message: (
        <Stack gap='xs'>
          <Text>Delete supplier '{supplier.name}'?</Text>
          <Text fw='bold'>This cannot be undone.</Text>
        </Stack>
      ),
      actions: [{
        label: 'Delete',
        role: 'destructive',
        handler: () => {
          onDeleteSupplier(supplier)
        }
      }]
    })
  }

  return (
    <Group gap='sm' wrap='nowrap' align='start' m='md'>
      {/* Supplier */}
      <Stack mr='auto' gap='0.25rem' align='start'>
        <Text>{supplier.name}</Text>
        <Text>GST: {WsTemplate.gstMethodName(supplier.gstMethod)}</Text>
      </Stack>

      {/* Control section (action button, drag handle) */}
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
            <Menu.Item leftSection={<IconPlus size={16} />} onClick={handleClickAdd}>Add Supplier</Menu.Item>
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
      {editModal.element}
    </Group>
  )
}

type AddSectionHandler = (section: WsTemplate.Section, anchor: WsTemplate.Section, position: 'before' | 'after') => void
type EditSectionHandler = (section: WsTemplate.Section) => void
type DeleteSectionHandler = (section: WsTemplate.Section) => void
type AddSupplierHandler = (supplier: WsTemplate.Supplier, afterSupplier: WsTemplate.Supplier) => void
type AddSupplierToSectionHandler = (supplier: WsTemplate.Supplier, section: WsTemplate.Section) => void
type EditSupplierHandler = (supplier: WsTemplate.Supplier) => void
type DeleteSupplierHandler = (supplier: WsTemplate.Supplier) => void