import { useEffect, useState } from 'react'
import { DragDropContext, Droppable, Draggable, DropResult, DraggableProvidedDragHandleProps } from '@hello-pangea/dnd'
import { Anchor, Button, Divider, Flex, Group, HoverCard, Loader, Menu, Space, Stack, Text, Title } from '@mantine/core'
import axios from 'axios'
import { useMutation, useQuery } from '@tanstack/react-query'
import { produce } from 'immer'
import { ObjectId } from 'bson'

import { Vendor } from 'src/models/Quiz'
import formatError from 'src/utils/format-error'
import { useLocation, useNavigate, useParams } from 'react-router'
import { IconAlertTriangleFilled, IconChevronDown, IconChevronLeft, IconChevronRight, IconGripVertical, IconPlus } from '@tabler/icons-react'
import wait from 'src/utils/wait'
import EditSectionModal, { EditSectionModalOptions } from 'src/app/QuizPage/EditSectionModal'
import EditItemModal, { EditItemModalOptions } from 'src/app/QuizPage/EditItemModal'
import ConfirmDeleteModal, { ConfirmDeleteModalOptions } from 'src/app/QuizPage/ConfirmDeleteModal'
import useRepeatedModal from 'src/common/use-repeated-modal'

export default function EditVendorItemsPage() {
  const { vendorId } = useParams()
  const location = useLocation()
  const navigate = useNavigate()
  const vendorName = location.state?.vendorName

  // Load vendor

  const { data: vendor, isLoading: isLoadingVendor, error: vendorError, refetch: fetchVendor } = useQuery({
    queryKey: ['vendor', vendorId],
    queryFn: async () => {
      // console.info(`! Making request to /api/vendor [Edit page]`)
      const response = await wait(axios.get<Vendor>(`/api/vendor/${vendorId}`), { minMs: 500 })
      return response.data
    },
    // select: data => data.vendor,
    enabled: false,
    gcTime: 0
  })

  useEffect(() => {
    fetchVendor()
  }, [fetchVendor])

  // Items

  const [items, setItems] = useState<Vendor.Item[]>([])
  const [sections, setSections] = useState<Vendor.Section[]>([])

  useEffect(() => {
    if (vendor) {
      setItems(vendor.items)
      setSections(vendor.sections)
    }
  }, [vendor])

  const { mutate: submit, error: submitError, isPending: isSubmitting } = useMutation({
    mutationFn: async () => {
      const body = {
        items: items,
        sections: sections
      }

      return await wait(
        (await axios.post(`/api/vendor/${vendorId}/items`, body)).data,
        { minMs: 750 }
      )
    }
  })

  // console.info(vendorResponse?.vendor)
  return (
    <Stack align='flex-start'>
      <Group w='100%'>
        <Anchor
          href='#'
          mr='auto'
          onClick={() => navigate(`/vendor/${vendorId}`)}
        >
          <Group gap={2} align='center' fz='sm'>
            <IconChevronLeft size={15} />
            {vendor?.name ?? vendorName ?? 'Back'}
          </Group>
        </Anchor>
        {
          isSubmitting ? <Loader size='xs' color='gray.7' /> :
            submitError ? (
              <Group>
                <HoverCard width={280} shadow="md">
                  <HoverCard.Target>
                    <Group align='center' gap={8} c='red' fz='sm'>
                      <IconAlertTriangleFilled size={15} />
                      <Text fz='sm'>Save Error</Text>
                    </Group>
                  </HoverCard.Target>
                  <HoverCard.Dropdown>
                    <Stack align='start'>
                      <Text size="sm">
                        {formatError(submitError)}
                      </Text>
                      <Button
                        variant='outline'
                        size='compact-xs'
                        ml='auto'
                        onClick={() => submit()}
                      >
                        Retry
                      </Button>
                      {/* <Anchor fz='sm' onClick={() => submit()}>Retry</Anchor> */}
                    </Stack>
                  </HoverCard.Dropdown>
                </HoverCard>
              </Group>
            ) :
              null
        }
      </Group>
      {
        isLoadingVendor ? <Text>Loading...</Text> :
          vendorError ? <Text c='red'>{formatError(vendorError)}</Text> :
            <ItemList
              items={items}
              setItems={setItems}
              sections={sections}
              setSections={setSections}
              submit={submit}
            />
      }
    </Stack >
  )
}

function ItemList({ items, setItems, sections, setSections, submit }: {
  items: Vendor.Item[],
  setItems: (value: Vendor.Item[]) => void,
  sections: Vendor.Section[],
  setSections: (value: Vendor.Section[]) => void,
  submit: () => void
}) {
  const editSectionModal = useRepeatedModal()
  const [editSectionModalOptions, setEditSectionModalOptions] = useState<EditSectionModalOptions>(EditSectionModalOptions.empty)

  const editItemModal = useRepeatedModal()
  const [editItemModalOptions, setEditItemModalOptions] = useState<EditItemModalOptions>(EditItemModalOptions.empty)

  const deleteModal = useRepeatedModal()
  const [deleteModalOptions, setDeleteModalOptions] = useState<ConfirmDeleteModalOptions>(ConfirmDeleteModalOptions.empty)

  const [collapsedSectionIds, setCollapsedSectionIds] = useState<string[]>([])

  function handleAddSection(atSectionIndex: number) {
    setEditSectionModalOptions({
      title: 'Add Section',
      fields: { name: '' },
      onSave: fields => {
        const newSections = produce(sections, sections => {
          const newSection: Vendor.Section = {
            id: new ObjectId().toString(),
            name: fields.name,
            rows: []
          }

          sections.splice(atSectionIndex, 0, newSection)
        })

        setSections(newSections)
        submit()
      }
    })

    editSectionModal.open()
  }

  function handleEditSection(section: Vendor.Section, sectionIndex: number) {
    setEditSectionModalOptions({
      title: 'Edit Section',
      fields: {
        name: section.name
      },
      onSave: fields => {
        const newSections = produce(sections, sections => {
          sections[sectionIndex].name = fields.name
        })

        setSections(newSections)
        submit()
      }
    })

    editSectionModal.open()
  }

  function handleDeleteSection(section: Vendor.Section, sectionIndex: number) {
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

        setSections(newSections)
        submit()
      }
    })

    deleteModal.open()
  }

  function handleAddItem(atRowIndex: number, section: Vendor.Section, sectionIndex: number) {
    setEditItemModalOptions({
      title: 'Add Item',
      fields: { name: '', code: '' },
      validateCode: code => validateItemCode(null, code),
      onChange: fields => {
        const newItem: Vendor.Item = {
          id: new ObjectId().toString(),
          name: fields.name,
          code: fields.code
        }

        const newItems = produce(items, items => {
          items.push(newItem)
        })

        const newSections = produce(sections, sections => {
          const newRow: Vendor.Row = {
            itemId: newItem.id
          }

          sections[sectionIndex].rows.splice(atRowIndex, 0, newRow)
        })

        setItems(newItems)
        setSections(newSections)
        submit()
      }
    })

    editItemModal.open()
  }

  function handleEditItem(item: Vendor.Item, rowIndex: number, section: Vendor.Section, sectionIndex: number) {
    setEditItemModalOptions({
      title: 'Edit Item',
      fields: {
        name: item.name,
        code: item.code
      },
      validateCode: code => validateItemCode(item, code),
      onChange: fields => {
        const newItems = produce(items, items => {
          const index = items.findIndex(x => x.id == item.id)
          items[index].name = fields.name.trim()
          items[index].code = fields.code.trim()
        })

        setItems(newItems)
        submit()
      }
    })

    editItemModal.open()
  }

  function handleDeleteItem(item: Vendor.Item, rowIndex: number, section: Vendor.Section, sectionIndex: number) {
    setDeleteModalOptions({
      message: (
        <Stack gap='xs'>
          <Text>Delete item '{item.name}'?</Text>
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

        setItems(newItems)
        setSections(newSections)
        submit()
      }
    })

    deleteModal.open()
  }

  function validateItemCode(item: Vendor.Item | null, code: string): string | null {
    const dup = items.find(x => x.id != item?.id && x.code.trim() == code.trim())
    return dup ? `Code is duplicated: used by item '${dup.name}'` : null
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

      /*
      // Old Gemini code

      const sourceSectionId = source.droppableId
      const destinationSectionId = destination.droppableId

      const sourceSectionIndex = sections.findIndex(section => section.id === sourceSectionId)
      const destinationSectionIndex = sections.findIndex(section => section.id === destinationSectionId)

      const sourceRows = [...sections[sourceSectionIndex].rows]
      const destinationRows = sourceSectionId === destinationSectionId ? sourceRows : [...sections[destinationSectionIndex].rows]

      const [draggedItem] = sourceRows.splice(source.index, 1) // Remove from source
      destinationRows.splice(destination.index, 0, draggedItem) // Insert into destination

      const newSections = [...sections]

      newSections[sourceSectionIndex] = { // Replace source section's rows with new source rows
        ...newSections[sourceSectionIndex],
        rows: sourceRows,
      }

      if (sourceSectionId !== destinationSectionId) {
        newSections[destinationSectionIndex] = { // Replace destination section's rows with new destination rows
          ...newSections[destinationSectionIndex],
          rows: destinationRows,
        }
      }
      */

      setSections(newSections)

    } else if (type === 'section') {
      // Reordering sections

      const newSections = produce(sections, sections => {
        const [draggedSection] = sections.splice(source.index, 1)
        sections.splice(destination.index, 0, draggedSection)
      })

      /*
      // Old Gemini code
      const newSections = [...sections]
      const [draggedSection] = newSections.splice(source.index, 1)
      newSections.splice(destination.index, 0, draggedSection)
      */

      setSections(newSections)
    }

    submit()
  }

  function handleToggleSection(sectionId: string) {
    const newValue = produce(collapsedSectionIds, value => {
      const index = value.indexOf(sectionId)

      if (index >= 0) {
        value.splice(index, 1)
      } else {
        value.push(sectionId)
      }
    })

    setCollapsedSectionIds(newValue)
  }

  return (
    <>
      <DragDropContext onDragEnd={onDragEnd}>
        {/* Droppable of sections */}
        <Droppable droppableId='sections-droppable' direction='vertical' type='section'>
          {provided => (
            // Stack of sections
            <Stack
              {...provided.droppableProps}
              ref={provided.innerRef}
              gap={0}
              w='100%'
            >
              {sections.map((section, sectionIndex) => (
                // One section
                <Draggable draggableId={section.id} index={sectionIndex} key={section.id}>
                  {provided => (
                    // Stack of section header and items
                    <Stack
                      ref={provided.innerRef}
                      {...provided.draggableProps}
                      style={provided.draggableProps.style}
                      gap={0}
                      bg='var(--mantine-color-body)'
                    >
                      {/* Section header */}
                      <SectionHeader
                        section={section}
                        dragHandleProps={provided.dragHandleProps}
                        onEdit={() => handleEditSection(section, sectionIndex)}
                        onDelete={() => handleDeleteSection(section, sectionIndex)}
                        onAddItem={() => handleAddItem(section.rows.length, section, sectionIndex)}
                        onAddSectionAbove={() => handleAddSection(sectionIndex)}
                        onAddSectionBelow={() => handleAddSection(sectionIndex + 1)}
                        isExpanded={!collapsedSectionIds.includes(section.id)}
                        onToggleExpanded={() => handleToggleSection(section.id)}
                      />
                      {/* Droppable of items */}
                      {
                        !collapsedSectionIds.includes(section.id) &&
                        <Droppable droppableId={section.id} type='item'>
                          {(provided) => (
                            // Stack of items
                            <Stack
                              ref={provided.innerRef}
                              {...provided.droppableProps}
                              gap={0}
                              pl={15}
                              align='start'
                              className='w-full'
                            >
                              {section.rows.map((row, rowIndex) => (
                                // Draggable of row
                                <Draggable draggableId={row.itemId} index={rowIndex} key={row.itemId}>
                                  {(provided) => (
                                    // Row
                                    <Group
                                      ref={provided.innerRef}
                                      {...provided.draggableProps}
                                      style={{
                                        ...provided.draggableProps.style,
                                        borderBottom: '1px solid var(--mantine-color-dark-4)'
                                      }}
                                      py='sm'
                                      gap='xs'
                                      bg='var(--mantine-color-body)'
                                      className='w-full'
                                    >
                                      {(function () {
                                        const item = items.find(item => item.id == row.itemId)

                                        return (
                                          <RowComponent
                                            item={item}
                                            dragHandleProps={provided.dragHandleProps}
                                            onEdit={() => handleEditItem(item!, rowIndex, section, sectionIndex)}
                                            onDelete={() => handleDeleteItem(item!, rowIndex, section, sectionIndex)}
                                            onAddItemAbove={() => handleAddItem(rowIndex, section, sectionIndex)}
                                            onAddItemBelow={() => handleAddItem(rowIndex + 1, section, sectionIndex)}
                                          />
                                        )
                                      })()}
                                    </Group>
                                  )}
                                </Draggable>
                              ))}
                              {provided.placeholder}
                              {/* <Button
                                variant='default'
                                size='xs'
                                leftSection={<IconPlus size={12} />}
                                my='sm'
                                onClick={() => handleAddItem(section.rows.length, section, sectionIndex)}
                              >
                                Add Item
                              </Button> */}
                            </Stack>
                          )}
                        </Droppable>
                      }
                    </Stack>
                  )}
                </Draggable>
              ))}
              {provided.placeholder}
              <Group>
                <Button
                  variant='default'
                  size='sm'
                  leftSection={<IconPlus size={13} />}
                  my='md'
                  onClick={() => handleAddSection(sections.length)}
                >
                  Add Section
                </Button>
              </Group>
            </Stack>
          )}
        </Droppable>
      </DragDropContext>

      {/* Modals */}
      {editSectionModal.modalIDs.map(id => (
        <EditSectionModal key={id} opened={editSectionModal.isOpened(id)} close={editSectionModal.close} options={editSectionModalOptions} />
      ))}
      {editItemModal.modalIDs.map(id => (
        <EditItemModal key={id} opened={editItemModal.isOpened(id)} close={editItemModal.close} options={editItemModalOptions} />
      ))}
      {deleteModal.modalIDs.map(id => (
        <ConfirmDeleteModal key={id} opened={deleteModal.isOpened(id)} close={deleteModal.close} options={deleteModalOptions} />
      ))}
    </>
  )
}

function SectionHeader({ section, dragHandleProps, onEdit, onDelete, onAddItem, onAddSectionAbove, onAddSectionBelow, isExpanded, onToggleExpanded }: {
  section: Vendor.Section
  dragHandleProps: DraggableProvidedDragHandleProps | null
  onEdit: () => void,
  onDelete: () => void
  onAddItem: () => void
  onAddSectionAbove: () => void
  onAddSectionBelow: () => void
  isExpanded: boolean
  onToggleExpanded: () => void
}) {
  return (
    <>
      <Flex
        direction={{ base: 'column', xs: 'row' }}
        align={{ base: 'flex-start', xs: 'center' }}
        justify='stretch'
        gap={{ base: 'xs', xs: 'md' }}
        wrap='nowrap'
        py='md'
      >
        {/* Name */}
        <Group gap='0' align='center' wrap='nowrap' mr='auto'>
          <span {...dragHandleProps} className='mr-2'>
            <IconGripVertical stroke={1.5} />
            {/* <IconMenuOrder /> */}
            {/* <IconArrowsMoveVertical /> */}
            {/* <IconArrowsSort/> */}
            {/* <IconBaselineDensityMedium /> */}
            {/* <IconMenu /> */}
          </span>
          {/* For some reason, Tailwind 'leading-' doesn't work here */}
          <Title order={4} c='gray.0' style={{ lineHeight: '1.5rem' }}>
            {section.name}
          </Title>
          <Button
            variant='transparent'
            size='compact-xs'
            onClick={() => onToggleExpanded()}
            className='translate-y-0.5'
          >
            {isExpanded ?
              <IconChevronDown size={22} /> :
              <IconChevronRight size={22} className='-translate-y-[2px]' />
            }
          </Button>
        </Group>
        {/* Buttons */}
        <Group gap='0' wrap='nowrap'>
          <Menu offset={6} position='bottom-end'>
            <Menu.Target>
              <Button
                variant='subtle'
                size='compact-sm'
              >
                Add
              </Button>
            </Menu.Target>
            <Menu.Dropdown>
              <Menu.Item onClick={onAddItem}>
                Add Item
              </Menu.Item>
              <Menu.Item onClick={onAddSectionAbove}>
                Add Section Above
              </Menu.Item>
              <Menu.Item onClick={onAddSectionBelow}>
                Add Section Below
              </Menu.Item>
            </Menu.Dropdown>
          </Menu>
          <Button
            variant='subtle'
            size='compact-sm'
            onClick={() => onEdit()}
          >
            Edit
          </Button>
          <Button
            variant='subtle'
            size='compact-sm'
            onClick={() => onDelete()}
          >
            Delete
          </Button>
        </Group>
      </Flex>
      <Divider />
    </>
  )
}

function RowComponent({ item, dragHandleProps, onEdit, onDelete, onAddItemAbove, onAddItemBelow }: {
  item: Vendor.Item | undefined,
  dragHandleProps: DraggableProvidedDragHandleProps | null,
  onEdit: () => void,
  onDelete: () => void,
  onAddItemAbove: () => void,
  onAddItemBelow: () => void
}) {
  return (
    <Flex
      direction={{ base: 'column', xs: 'row' }}
      align={{ base: 'flex-start', xs: 'center' }}
      columnGap='md'
      rowGap='0.5rem'
      wrap='nowrap'
      className='w-full'
    >
      <Group gap='xs' wrap='nowrap' mr='auto'>
        <span {...dragHandleProps}>
          <IconGripVertical size={18} stroke={1.5} />
          {/* <IconArrowsMoveVertical size={18} /> */}
          {/* <IconMenuOrder /> */}
          {/* <IconArrowsSort size={18}/> */}
          {/* <IconBaselineDensityMedium size={18}/> */}
          {/* <IconMenu size={18} /> */}
        </span>
        <Text mr='auto'>
          {item ?
            `${item.name} (${item.code})` :
            '<Item not found>'}
        </Text>
        <Space />
      </Group>
      <Group gap='0'>
        <Menu offset={6} position='bottom-end'>
          <Menu.Target>
            <Button variant='subtle' size='compact-sm'>
              Add
            </Button>
          </Menu.Target>
          <Menu.Dropdown>
            <Menu.Item onClick={onAddItemAbove}>
              Add Item Above
            </Menu.Item>
            <Menu.Item onClick={onAddItemBelow}>
              Add Item Below
            </Menu.Item>
          </Menu.Dropdown>
        </Menu>
        <Button
          variant='subtle'
          size='compact-sm'
          onClick={() => onEdit()}
        >
          Edit
        </Button>
        <Button
          variant='subtle'
          size='compact-sm'
          onClick={() => onDelete()}
        >
          Delete
        </Button>
      </Group>
    </Flex>
  )
}