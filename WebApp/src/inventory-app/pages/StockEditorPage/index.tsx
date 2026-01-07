import { useState } from 'react'
import { useParams } from 'react-router'
import { useQuery } from '@tanstack/react-query'
import { Anchor, Group, NumberInput, Stack, Table, Text, Title } from '@mantine/core'
import { IconChevronLeft } from '@tabler/icons-react'

import { useApi, usePath } from 'src/app/contexts'
import { InvStore } from 'src/inventory-app/models/InvStore'
import { InvStock } from 'src/inventory-app/models/InvStock'
import formatError from 'src/common/format-error'

export default function StockEditorPage() {
  const { storeId } = useParams()
  const { navigate } = usePath()
  const { axios } = useApi()
  const [quantityMap, setQuantityMap] = useState<Record<string, string>>({})

  const { data, isLoading, error } = useQuery({
    queryKey: ['store-with-stock', storeId],
    queryFn: async () => {
      const [store, stock] = await Promise.all([
        (await axios.get<InvStore>(`stores/${storeId}`)).data,
        (await axios.get<InvStock>(`stores/${storeId}/stock`)).data
      ])

      return { store, stock }
    }
  })

  function handleBack() {
    navigate(`/`)
  }

  if (isLoading) {
    return <Text>Loading...</Text>
  }

  if (error) {
    return <Text c='red'>{formatError(error)}</Text>
  }

  if (!data) {
    return <Text>???</Text>
  }

  return (
    <Stack>
      <Group align='center' pb='lg' pt='md'>
        <Anchor size='sm' onClick={handleBack}>
          <Group gap='0.2rem'>
            <IconChevronLeft size={18} />
            Back to Inventory
          </Group>
        </Anchor>
      </Group>

      <Title order={1} c='gray.1'>Edit Stock</Title>

      <ItemList
        store={data.store}
        stock={data.stock}
        quantityMap={quantityMap}
        setQuantityMap={setQuantityMap}
      />
    </Stack>
  )
}

function ItemList({ store, stock, quantityMap, setQuantityMap }: {
  store: InvStore
  stock: InvStock
  quantityMap: Record<string, string>
  setQuantityMap: React.Dispatch<React.SetStateAction<Record<string, string>>>
}) {
  return (
    <Stack gap='xl'>
      {store.catalog.sections.map(section => (
        <Stack key={section.id} gap={0}>
          <Title order={3} c='gray.3' pb='xs'>{section.name}</Title>
          <Table fz='md' tabularNums verticalSpacing='sm'>
            {
              section.id == store.catalog.sections[0].id &&
              <Table.Thead>
                <Table.Tr visibleFrom='sm'>
                  <Table.Th styles={{ th: { width: '40%' } }}>Name</Table.Th>
                  <Table.Th styles={{ th: { width: '25%' } }}>Code</Table.Th>
                  <Table.Th styles={{ th: { width: '25%' } }}>Quantity</Table.Th>
                </Table.Tr>
                <Table.Tr hiddenFrom='sm'>
                  <Table.Th styles={{ th: { width: '65%' } }}>Name / Code</Table.Th>
                  <Table.Th styles={{ th: { width: '35%' } }}>Quantity</Table.Th>
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

function TableRow({ item, qty, quantityMap, setQuantityMap }: {
  item: InvStore.Item
  qty: number
  quantityMap: Record<string, string>
  setQuantityMap: React.Dispatch<React.SetStateAction<Record<string, string>>>
}) {
  return (
    <Table.Tr key={item.id}>
      <Table.Td styles={{ td: { width: '40%' } }} visibleFrom='sm'>{item.name}</Table.Td>
      <Table.Td styles={{ td: { width: '25%' } }} visibleFrom='sm'>{item.code}</Table.Td>
      <Table.Td styles={{ td: { width: '25%' } }} visibleFrom='sm'>
        <QuantityCell
          itemId={item.id}
          originalQty={qty}
          quantityMap={quantityMap}
          setQuantityMap={setQuantityMap}
        />
      </Table.Td>
      <Table.Td styles={{ td: { width: '65%' } }} hiddenFrom='sm'>
        <Stack gap={0}>
          <Text>{item.name}</Text>
          <Text c='dimmed' size='sm'>{item.code}</Text>
        </Stack>
      </Table.Td>
      <Table.Td styles={{ td: { width: '35%' } }} hiddenFrom='sm'>
        <QuantityCell
          itemId={item.id}
          originalQty={qty}
          quantityMap={quantityMap}
          setQuantityMap={setQuantityMap}
        />
      </Table.Td>
    </Table.Tr>
  )
}

interface QuantityCellProps {
  itemId: string
  originalQty: number
  quantityMap: Record<string, string>
  setQuantityMap: React.Dispatch<React.SetStateAction<Record<string, string>>>
}

function QuantityCell({ itemId, originalQty, quantityMap, setQuantityMap }: QuantityCellProps) {
  const newValue = quantityMap[itemId]
  const displayQty = originalQty

  if (newValue !== undefined) {
    return (
      <Group>
        <NumberInput
          min={0}
          w='5rem'
          size='xs'
          value={newValue}
          onChange={(val) => setQuantityMap(prev => ({ ...prev, [itemId]: String(val) }))}
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
      </Group>
    )
  }

  return (
    <Group>
      <Text>{displayQty}</Text>
      <Anchor size='sm' onClick={() => {
        setQuantityMap(prev => ({ ...prev, [itemId]: String(displayQty) }))
      }}>
        Change
      </Anchor>
    </Group>
  )
}
