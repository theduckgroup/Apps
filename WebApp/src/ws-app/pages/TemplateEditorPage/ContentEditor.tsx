import { useCallback, useState } from 'react'
import { ActionIcon, Box, Button, Divider, Group, Menu, Paper, Stack, Text, Title } from '@mantine/core'
import { DragDropContext, Draggable, DraggableProvided, DraggableProvidedDragHandleProps, Droppable, DropResult } from '@hello-pangea/dnd'
import { IconChevronDown, IconChevronRight, IconDots, IconPencil, IconPlus, IconSelector, IconTrash } from '@tabler/icons-react'
import { produce } from 'immer'

import { WsTemplate } from 'src/ws-app/models/WsTemplate'
import { EditSupplierModal } from './EditSupplierModal'
import { EditSectionModal } from './EditSectionModal'
import { ConfirmModal } from 'src/utils/ConfirmModal'
import { Dispatch, Reducer } from 'src/utils/types-lib'
import useModal from 'src/utils/use-modal'

export function ContentEditor({ suppliers, sections, setData }: {
  suppliers: WsTemplate.Supplier[],
  sections: WsTemplate.Section[],
  setData: Dispatch<Reducer<[WsTemplate.Supplier[], WsTemplate.Section[]]>>
}) {
  const editSectionModal = useModal(EditSectionModal)

  // Can't hold this inside SectionHeader or Row because they will be deleted
  const confirmDeleteModal = useModal(ConfirmModal)

  // Can't hold this inside SectionComponent because it gets reset during drag/drop
  const [collapsedSectionIDs, setCollapsedSectionIDs] = useState<Set<string>>(new Set())

  const addSection: AddSectionFn = (newSection, anchor, position) => {
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

  const updateSection: UpdateSectionFn = (section) => {
    setData(([suppliers, sections]) => {
      const newSections = [...sections]
      const sectionIndex = newSections.findIndex(x => x.id == section.id)!
      newSections[sectionIndex] = section

      return [suppliers, newSections]
    })
  }

  const deleteSection: DeleteSectionFn = (section) => {
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

  const addSupplier: AddSupplierFn = (supplier, afterSupplier) => {
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

  const addSupplierToSection: AddSupplierToSectionFn = (supplier, section) => {
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

  const updateSupplier: UpdateSupplierFn = (supplier) => {
    setData(([suppliers, sections]) => {
      const newSuppliers = produce(suppliers, suppliers => {
        const index = suppliers.findIndex(x => x.id == supplier.id)
        suppliers[index] = supplier
      })

      return [newSuppliers, sections]
    })
  }

  const deleteSupplier: DeleteSupplierFn = (supplier) => {
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
      section: WsTemplate.newSection(),
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
                        supplierForId={id => suppliers.find(x => x.id == id)}
                        isExpanded={isSectionExpanded(section.id)}
                        setExpanded={value => setSectionExpanded(section.id, value)}
                        addSection={addSection}
                        updateSection={updateSection}
                        deleteSection={deleteSection}
                        addSupplier={addSupplier}
                        addSupplierToSection={addSupplierToSection}
                        updateSupplier={updateSupplier}
                        deleteSupplier={deleteSupplier}
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
  section, sectionIndex, supplierForId,
  isExpanded, setExpanded,
  addSection, updateSection, deleteSection,
  addSupplier, addSupplierToSection, updateSupplier, deleteSupplier,
  openConfirmDeleteModal,
  provided
}: {
  section: WsTemplate.Section,
  sectionIndex: number,
  supplierForId: (id: string) => WsTemplate.Supplier | undefined,
  isExpanded: boolean,
  setExpanded: (_: boolean) => void,
  addSection: AddSectionFn,
  updateSection: UpdateSectionFn,
  deleteSection: DeleteSectionFn,
  addSupplier: AddSupplierFn,
  addSupplierToSection: AddSupplierToSectionFn,
  updateSupplier: UpdateSupplierFn,
  deleteSupplier: UpdateSupplierFn,
  openConfirmDeleteModal: (_: ConfirmModal.Options) => void,
  provided: DraggableProvided
}) {
  const addSupplierModal = useModal(EditSupplierModal)

  const handleClickAddSupplier = () => {
    addSupplierModal.open({
      title: 'Add Suplier',
      supplier: WsTemplate.newSupplier(),
      onSave: newSupplier => {
        addSupplierToSection(newSupplier, section)
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
      ref={provided.innerRef} // eslint-disable-line react-hooks/refs
      {...provided.draggableProps} // eslint-disable-line react-hooks/refs
      style={provided.draggableProps.style} // eslint-disable-line react-hooks/refs
    >
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
                            <RowComponent
                              supplier={supplierForId(row.supplierId)!}
                              rowIndex={rowIndex}
                              addSupplier={addSupplier}
                              updateSupplier={updateSupplier}
                              deleteSupplier={deleteSupplier}
                              openConfirmDeleteModal={openConfirmDeleteModal}
                              dragHandleProps={provided.dragHandleProps}
                            />
                            {rowIndex < section.rows.length - 1 && <Divider ml='md' />}
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

function SectionHeader({
  section, sectionIndex,
  addSection, updateSection, deleteSection,
  openConfirmDeleteModal,
  isExpanded, setExpanded,
  dragHandleProps
}: {
  section: WsTemplate.Section
  sectionIndex: number,
  addSection: AddSectionFn,
  updateSection: UpdateSectionFn,
  deleteSection: DeleteSectionFn,
  openConfirmDeleteModal: (options: ConfirmModal.Options) => void,
  isExpanded: boolean
  setExpanded: (_: boolean) => void
  dragHandleProps: DraggableProvidedDragHandleProps | null
}) {
  const editSectionModal = useModal(EditSectionModal)

  const handleClickAdd = useCallback((position: 'before' | 'after') => {
    editSectionModal.open({
      title: 'Add Section',
      section: WsTemplate.newSection(),
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
      title: 'Delete section?',
      message: <Text>The section and its suppliers will be deleted.</Text>,
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
    <Stack gap={0}>
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
          <Menu offset={6} position='bottom-end' width={210}>
            <Menu.Target>
              <ActionIcon variant='subtle' size='md' color='gray'>
                <IconDots size={16} />
              </ActionIcon>
            </Menu.Target>
            <Menu.Dropdown>
              <Menu.Item leftSection={<IconPencil size={16} />} onClick={handleClickEdit}>Edit Section</Menu.Item>
              <Menu.Item leftSection={<IconTrash size={16} />} onClick={handleDelete}>Delete Section</Menu.Item>
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
            <IconSelector size={16} />
          </Box>
        </Group>

      </Group>
      {!isExpanded && <Divider />}
      {/* Modals */}
      {editSectionModal.element}
    </Stack>
  )
}

function RowComponent({
  supplier, rowIndex,
  addSupplier, updateSupplier, deleteSupplier,
  openConfirmDeleteModal,
  dragHandleProps
}: {
  supplier: WsTemplate.Supplier
  rowIndex: number
  addSupplier: AddSupplierFn
  updateSupplier: UpdateSupplierFn
  deleteSupplier: DeleteSupplierFn
  openConfirmDeleteModal: (_: ConfirmModal.Options) => void
  dragHandleProps: DraggableProvidedDragHandleProps | null
}) {
  const editModal = useModal(EditSupplierModal)

  const handleClickAdd = () => {
    editModal.open({
      title: 'Add Supplier',
      supplier: WsTemplate.newSupplier(),
      onSave: newSupplier => {
        addSupplier(newSupplier, /* after */ supplier)
      }
    })
  }

  const handleClickEdit = () => {
    editModal.open({
      title: 'Edit Supplier',
      supplier,
      onSave: modifiedSupplier => {
        updateSupplier(modifiedSupplier)
      }
    })
  }

  const handleClickDelete = () => {
    openConfirmDeleteModal({
      title: 'Delete supplier?',
      actions: [{
        label: 'Delete',
        role: 'destructive',
        handler: () => {
          deleteSupplier(supplier)
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
            <Menu.Item leftSection={<IconPencil size={16} />} onClick={handleClickEdit}>Edit Supplier</Menu.Item>
            <Menu.Item leftSection={<IconTrash size={16} />} onClick={handleClickDelete}>Delete Supplier</Menu.Item>
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

type AddSectionFn = (section: WsTemplate.Section, anchor: WsTemplate.Section, position: 'before' | 'after') => void
type UpdateSectionFn = (section: WsTemplate.Section) => void
type DeleteSectionFn = (section: WsTemplate.Section) => void
type AddSupplierFn = (supplier: WsTemplate.Supplier, afterSupplier: WsTemplate.Supplier) => void
type AddSupplierToSectionFn = (supplier: WsTemplate.Supplier, section: WsTemplate.Section) => void
type UpdateSupplierFn = (supplier: WsTemplate.Supplier) => void
type DeleteSupplierFn = (supplier: WsTemplate.Supplier) => void