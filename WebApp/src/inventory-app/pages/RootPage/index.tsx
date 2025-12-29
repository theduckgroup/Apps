import { useEffect, useState } from 'react'
import { Button, Group, Space, Stack, Table, Title } from '@mantine/core'
import { useNavigate } from 'react-router'
import axios from 'axios'
import { useQuery } from '@tanstack/react-query'
import { Text } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { IconEdit } from '@tabler/icons-react'

import { InvStore } from 'src/inventory-app/models/InvStore'
import { InvStoreStock } from 'src/inventory-app/models/InvStoreStock'
import QrModal from './QrModal'
import eventHub from 'src/inventory-app/event-hub'
import formatError from 'src/common/format-error'
import { useApi, usePath } from 'src/app/contexts'
import { NonProdEnvWarning } from 'src/app/NonProdEnvWarning'

export default function RootPage() {
  // const { user } = useAuth()
  const { axios } = useApi()
  const { navigate } = usePath()
  const storeId = '69509ae69da8c740e58d83c1'

  const { data, isLoading, error, refetch: fetch } = useQuery({
    // queryKey: ['store-with-stock', 'code=ND_CENTRAL_KITCHEN'],
    queryKey: ['store-with-stock'],
    queryFn: async () => {
      const [store, stock] = await Promise.all([
        (await axios.get<InvStore>(`store/${storeId}`)).data,
        (await axios.get<InvStoreStock>(`store/${storeId}/stock`)).data
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

  const [qrModalOpened, { open: openQrModal, close: closeQrModal }] = useDisclosure(false)
  const [qrModalItem, setQrModalItem] = useState<InvStore.Item | undefined>()

  function handleViewCode(item: InvStore.Item) {
    setQrModalItem(item)
    openQrModal()
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
            leftSection={<IconEdit size={15} />}
            onClick={() => handleEditItems()}
          >
            Edit Items
          </Button>
        </Group>
        <ItemList store={data.store} stock={data.stock} onViewCode={handleViewCode} />
      </Stack>

      {/* Modals */}
      {/* <QrModal
        opened={qrModalOpened}
        onClose={() => {
          closeQrModal()
          setQrModalItem(undefined)
        }}
        item={qrModalItem}
      /> */}
    </>
  )
}

function ItemList({ store, stock, onViewCode }: {
  store: InvStore,
  stock: InvStoreStock,
  onViewCode: (item: InvStore.Item) => void
}) {
  return (
    <Stack gap='xl'>
      {store.catalog.sections.map(section => (
        <Stack key={section.id} gap={0}>
          <Title order={3} c='gray.3' pb='xs'>{section.name}</Title>
          <Table fz='md' tabularNums verticalSpacing='sm'>
            <Table.Thead>
              <Table.Tr>
                <Table.Th styles={{
                  th: { width: '40%' }
                }}>
                  Name
                </Table.Th>
                <Table.Th styles={{
                  th: { width: '25%' }
                }}>
                  Code
                </Table.Th>
                <Table.Th styles={{
                  th: { width: '10%' }
                }}>
                  Quantity
                </Table.Th>
                <Table.Th></Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {section.rows.map(row => {
                const item = store.catalog.items.find(x => x.id == row.itemId)
                const attrs = stock.itemAttributes.find(x => x.itemId == row.itemId)

                if (!item) {
                  return null
                }

                return (
                  <Table.Tr key={item.id}>
                    <Table.Td>{item.name}</Table.Td>
                    <Table.Td>{item.code}</Table.Td>
                    <Table.Td>{attrs?.quantity ?? '-'}</Table.Td>
                    <Table.Td>
                      <Group justify='end' className='ml-auto'>
                        <Button variant='subtle' size='compact-xs' onClick={() => onViewCode(item)}>
                          {/* <IconQrcode size={24} stroke={1.33} /> */}
                          View Code
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