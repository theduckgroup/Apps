import { useEffect, useMemo, useRef, useState } from 'react'
import { useBlocker, useParams } from 'react-router'
import { useMutation } from '@tanstack/react-query'
import { Anchor, Group, NumberInput, Stack, Table, Text, Title } from '@mantine/core'
import { IconChevronLeft } from '@tabler/icons-react'

import { useApi, usePath } from 'src/app/contexts'
import { InvStore } from 'src/inventory-app/models/InvStore'
import { InvStock } from 'src/inventory-app/models/InvStock'
import formatError from 'src/common/format-error'
import { EditorFooter } from 'src/utils/EditorFooter'
import { UnsavedChangesModal } from 'src/utils/UnsavedChangesModal'
import { useBeforeUnload } from 'src/utils/use-before-unload'

export default function StockEditorPage() {
  const { storeId } = useParams()
  const { navigate } = usePath()
  const { axios } = useApi()
  const [didChange, setDidChange] = useState(false)
  const [quantityMap, setQuantityMap] = useState<Record<string, string>>({})
  const [storeWithStock, setStoreWithStock] = useState<{ store: InvStore, stock: InvStock } | null>(null)
  const mainRef = useRef<HTMLDivElement>(null)

  const { mutate: loadStoreWithStock, isPending: isLoading, error } = useMutation({
    mutationKey: ['store-with-stock', storeId],
    mutationFn: async () => {
      const [store, stock] = await Promise.all([
        (await axios.get<InvStore>(`stores/${storeId}`)).data,
        (await axios.get<InvStock>(`stores/${storeId}/stock`)).data
      ])

      return { store, stock }
    },
    onSuccess: (result) => {
      setStoreWithStock(result)
    }
  })

  useEffect(() => {
    loadStoreWithStock()
  }, [loadStoreWithStock])

  const hasUnsavedChanges = useMemo(() => {
    if (!storeWithStock) return false

    return Object.entries(quantityMap).some(([itemId, newQty]) => {
      const attrs = storeWithStock.stock.itemAttributes.find(x => x.itemId === itemId)
      const originalQty = attrs?.quantity ?? 0
      return parseInt(newQty, 10) !== originalQty
    })
  }, [quantityMap, storeWithStock])

  const { mutateAsync: saveStockAsync } = useMutation({
    mutationFn: async () => {
      const changes = Object.entries(quantityMap).map(([itemId, quantity]) => ({
        itemId,
        quantity: {
          set: { value: parseInt(quantity, 10) }
        }
      }))

      await axios.post(`stores/${storeId}/stock`, { changes })
    },
    onSuccess: () => {
      if (storeWithStock) {
        const updatedItemAttributes = storeWithStock.stock.itemAttributes.map(attr => {
          const newQty = quantityMap[attr.itemId]
          if (newQty !== undefined) {
            return { ...attr, quantity: parseInt(newQty, 10) }
          }
          return attr
        })
        setStoreWithStock({
          ...storeWithStock,
          stock: { ...storeWithStock.stock, itemAttributes: updatedItemAttributes }
        })
      }

      setQuantityMap({})
    }
  })

  const blocker = useBlocker(useMemo(() => hasUnsavedChanges, [hasUnsavedChanges]))
  useBeforeUnload(hasUnsavedChanges)

  function handleBack() {
    navigate(`/`)
  }

  function handleQuantityChange(itemId: string, value: string) {
    setQuantityMap(prev => ({ ...prev, [itemId]: value }))
    setDidChange(true)
  }

  return (
    <>
      <div ref={mainRef} className='flex flex-col gap-6 items-start'>
        <Anchor size='sm' onClick={handleBack}>
          <Group gap='0.2rem'>
            <IconChevronLeft size={18} />
            Back to Inventory
          </Group>
        </Anchor>


        {(() => {
          if (isLoading) {
            return <Text>Loading...</Text>
          }

          if (error) {
            return <Text c='red'>{formatError(error)}</Text>
          }

          if (!storeWithStock) {
            return <Text>???</Text>
          }

          return (
            <div className='w-full flex flex-col gap-6'>
              <Title order={1} c='gray.1'>Edit Stock</Title>

              <ItemList
                store={storeWithStock.store}
                stock={storeWithStock.stock}
                quantityMap={quantityMap}
                setQuantityMap={setQuantityMap}
                onQuantityChange={handleQuantityChange}
              />
            </div>
          )
        })()}

      </div>

      {didChange &&
        <EditorFooter
          editorRef={mainRef}
          hasUnsavedChanges={hasUnsavedChanges}
          save={() => saveStockAsync()}
          saveButtonLabel='Save Changes'
        />
      }

      <UnsavedChangesModal
        blocker={blocker}
        save={() => saveStockAsync()}
      />
    </>
  )
}

function ItemList({ store, stock, quantityMap, setQuantityMap, onQuantityChange }: {
  store: InvStore
  stock: InvStock
  quantityMap: Record<string, string>
  setQuantityMap: React.Dispatch<React.SetStateAction<Record<string, string>>>
  onQuantityChange: (itemId: string, value: string) => void
}) {
  return (
    <Stack gap='xl' w='100%'>
      {store.catalog.sections.map(section => (
        <Stack key={section.id} gap={0}>
          <Title order={3} c='gray.3' pb='xs'>{section.name}</Title>
          <Table fz='md' tabularNums verticalSpacing='sm'>
            {
              section.id == store.catalog.sections[0].id &&
              <Table.Thead>
                <Table.Tr visibleFrom='xs'>
                  <Table.Th styles={{ th: { width: '50%' } }}>Name</Table.Th>
                  <Table.Th styles={{ th: { width: '30%' } }}>Code</Table.Th>
                  <Table.Th styles={{ th: { width: '20%' } }}>Quantity</Table.Th>
                </Table.Tr>
                <Table.Tr hiddenFrom='xs'>
                  <Table.Th styles={{ th: { width: '70%' } }}>Name / Code</Table.Th>
                  <Table.Th styles={{ th: { width: '30%' } }}>Quantity</Table.Th>
                </Table.Tr>
              </Table.Thead>
            }
            <Table.Tbody>
              {section.rows.map(row => {
                const item = store.catalog.items.find(x => x.id == row.itemId)
                const attrs = stock.itemAttributes.find(x => x.itemId == row.itemId)

                if (!item) {
                  return null
                }

                return (
                  <TableRow
                    key={item.id}
                    item={item}
                    qty={attrs?.quantity ?? 0}
                    quantityMap={quantityMap}
                    setQuantityMap={setQuantityMap}
                    onQuantityChange={onQuantityChange}
                  />
                )
              })}
            </Table.Tbody>
          </Table>
        </Stack>
      ))}
    </Stack>
  )
}

function TableRow({ item, qty, quantityMap, setQuantityMap, onQuantityChange }: {
  item: InvStore.Item
  qty: number
  quantityMap: Record<string, string>
  setQuantityMap: React.Dispatch<React.SetStateAction<Record<string, string>>>
  onQuantityChange: (itemId: string, value: string) => void
}) {
  return (
    <Table.Tr key={item.id}>
      <Table.Td styles={{ td: { width: '50%' } }} visibleFrom='xs'>{item.name}</Table.Td>
      <Table.Td styles={{ td: { width: '30%' } }} visibleFrom='xs'>{item.code}</Table.Td>
      <Table.Td styles={{ td: { width: '20%' } }} visibleFrom='xs'>
        <QuantityCell
          itemId={item.id}
          originalQty={qty}
          quantityMap={quantityMap}
          setQuantityMap={setQuantityMap}
          onQuantityChange={onQuantityChange}
        />
      </Table.Td>
      <Table.Td styles={{ td: { width: '70%' } }} hiddenFrom='xs'>
        <Stack gap={0}>
          <Text>{item.name}</Text>
          <Text c='dimmed' size='sm'>{item.code}</Text>
        </Stack>
      </Table.Td>
      <Table.Td styles={{ td: { width: '30%' } }} hiddenFrom='xs'>
        <QuantityCell
          itemId={item.id}
          originalQty={qty}
          quantityMap={quantityMap}
          setQuantityMap={setQuantityMap}
          onQuantityChange={onQuantityChange}
        />
      </Table.Td>
    </Table.Tr>
  )
}

function QuantityCell({ itemId, originalQty, quantityMap, setQuantityMap, onQuantityChange }: {
  itemId: string
  originalQty: number
  quantityMap: Record<string, string>
  setQuantityMap: React.Dispatch<React.SetStateAction<Record<string, string>>>
  onQuantityChange: (itemId: string, value: string) => void
}) {
  const newValue = quantityMap[itemId]
  const displayQty = originalQty
  const inputRef = useRef<HTMLInputElement>(null)

  function handleChangeClick() {
    setQuantityMap(prev => ({ ...prev, [itemId]: String(displayQty) }))
    onQuantityChange(itemId, String(displayQty))

    setTimeout(() => {
      if (inputRef.current) {
        inputRef.current.focus()
        inputRef.current.select()
      }
    }, 0)
  }

  return (
    <div className='min-h-8 flex flex-row items-center'>
      {(newValue !== undefined) ?
        <Group wrap='nowrap'>
          <NumberInput
            min={0}
            w='60px'
            size='xs'
            fw={600}
            allowDecimal={false}
            allowNegative={false}
            value={newValue}
            onChange={(val) => onQuantityChange(itemId, String(val))}
            ref={inputRef}
            styles={{
              input: {
                fontSize: '0.9rem',
                padding: '0.25rem 0.5rem'
              }
            }}
          />
          <Anchor size='sm' onClick={() => {
            setQuantityMap(prev => {
              const copy = { ...prev }
              delete copy[itemId]
              return copy
            })
          }}>
            Reset
          </Anchor>
        </Group> :
        <Group>
          <Text miw='36px'>{displayQty}</Text>
          <Anchor size='sm' onClick={handleChangeClick}>
            Change
          </Anchor>
        </Group>
      }
    </div>
  )
}
