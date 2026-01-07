import { useEffect } from 'react'
import { Button, Group, Space, Stack, Table, Title } from '@mantine/core'
import { useQuery } from '@tanstack/react-query'
import { Text } from '@mantine/core'
import { IconEdit, IconList, IconStack2Filled } from '@tabler/icons-react'

import { InvStore } from 'src/inventory-app/models/InvStore'
import { InvStock } from 'src/inventory-app/models/InvStock'
import QrModal from './QRCodeModal'
import eventHub from 'src/inventory-app/event-hub'
import formatError from 'src/common/format-error'
import { useApi, usePath } from 'src/app/contexts'
import { NonProdEnvWarning } from 'src/app/NonProdEnvWarning'
import useModal from 'src/utils/use-modal'

export default function RootPage() {
  // const { user } = useAuth()
  const { axios } = useApi()
  const { navigate } = usePath()
  const storeId = '69509ae69da8c740e58d83c1'

  const qrModal = useModal(QrModal)

  const { data, isLoading, error, refetch: fetch } = useQuery({
    // queryKey: ['store-with-stock', 'code=ND_CENTRAL_KITCHEN'],
    queryKey: ['store-with-stock'],
    queryFn: async () => {
      const [store, stock] = await Promise.all([
        (await axios.get<InvStore>(`stores/${storeId}`)).data,
        (await axios.get<InvStock>(`stores/${storeId}/stock`)).data
      ])

      return { store, stock }
    },
    // select: data => data
  })

  useEffect(() => {
    return eventHub.onStoreChanged(storeId, fetch)
  }, [fetch])

  function handleEditItems() {
    navigate(`/store/${storeId}/editor`, {
      state: {
        storeName: data?.store.name ?? ''
      }
    })
  }

  function handleEditStock() {
    navigate(`/store/${storeId}/stock/editor`)
  }

  function handleViewCode(item: InvStore.Item) {
    qrModal.open({ item })
  }

  if (isLoading) {
    return <Text>Loading...</Text>
  }

  if (error) {
    return <Text c='red' fz='sm'>{formatError(error)}</Text>
  }

  if (!data) {
    return <Text>???</Text>
  }

  return (
    <>
      <Stack>
        <NonProdEnvWarning />
        <Group align='center' pb='lg' pt='md'>
          {/* data.store.name */}
          <Title order={1} c='gray.0'>Inventory</Title>
          <Space flex={1} />
          <Button
            variant='filled'
            size='sm'
            leftSection={<IconStack2Filled size={17} />}
            onClick={() => handleEditStock()}
          >
            Edit Stock
          </Button>
          <Button
            variant='filled'
            size='sm'
            leftSection={<IconList size={17} />}
            onClick={() => handleEditItems()}
          >
            Edit Items
          </Button>
        </Group>
        <ItemList store={data.store} stock={data.stock} onViewCode={handleViewCode} />
      </Stack>

      {qrModal.element}
    </>
  )
}

function ItemList({ store, stock, onViewCode }: {
  store: InvStore,
  stock: InvStock,
  onViewCode: (item: InvStore.Item) => void
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
                {/* Desktop header */}
                <Table.Tr visibleFrom='sm'>
                  <Table.Th styles={{ th: { width: '40%' } }}>Name</Table.Th>
                  <Table.Th styles={{ th: { width: '25%' } }}>Code</Table.Th>
                  <Table.Th styles={{ th: { width: '10%' } }}>Quantity</Table.Th>
                  <Table.Th>{/* View Code */}</Table.Th>
                </Table.Tr>
                {/* Mobile header */}
                <Table.Tr hiddenFrom='sm'>
                  <Table.Th styles={{ th: { width: '65%' } }}>Name / Code</Table.Th>
                  <Table.Th styles={{ th: { width: '15%' } }}>Qty</Table.Th>
                  <Table.Th>{/* Code */}</Table.Th>
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
                  <Table.Tr key={item.id}>
                    {/* Desktop row */}
                    <Table.Td styles={{ td: { width: '40%' } }} visibleFrom='sm'>{item.name}</Table.Td>
                    <Table.Td styles={{ td: { width: '25%' } }} visibleFrom='sm'>{item.code}</Table.Td>
                    <Table.Td styles={{ td: { width: '10%' } }} visibleFrom='sm'>{attrs?.quantity ?? '-'}</Table.Td>
                    <Table.Td visibleFrom='sm'>
                      <Group justify='end' className='ml-auto'>
                        <Button variant='subtle' size='compact-xs' onClick={() => onViewCode(item)}>
                          View Code
                        </Button>
                      </Group>
                    </Table.Td>

                    {/* Mobile row */}
                    <Table.Td styles={{ td: { width: '65%' } }} hiddenFrom='sm'>
                      <Stack gap={0}>
                        <Text>{item.name}</Text>
                        <Text c='dimmed' size='sm'>{item.code}</Text>
                      </Stack>
                    </Table.Td>
                    <Table.Td styles={{ td: { width: '15%' } }} hiddenFrom='sm'>{attrs?.quantity ?? '-'}</Table.Td>
                    <Table.Td hiddenFrom='sm'>
                      <Group justify='end' className='ml-auto'>
                        <Button variant='subtle' size='compact-xs' onClick={() => onViewCode(item)}>
                          Code
                        </Button>
                      </Group>
                    </Table.Td>
                  </Table.Tr>
                )
              })}
            </Table.Tbody>
          </Table>
        </Stack>
      ))}
    </Stack>
  )
}