import { useEffect, useState } from 'react'
import { useParams } from 'react-router'
import { useQuery } from '@tanstack/react-query'
import { Group, Stack, Text, Title } from '@mantine/core'
import { IconChevronLeft } from '@tabler/icons-react'
import { Anchor } from '@mantine/core'

import { useApi, usePath } from 'src/app/contexts'
import { InvStore } from 'src/inventory-app/models/InvStore'
import { InvStock } from 'src/inventory-app/models/InvStock'
import formatError from 'src/common/format-error'

export default function StockEditorPage() {
  const { storeId } = useParams()
  const { navigate } = usePath()
  const { axios } = useApi()

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
    <>
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

        <Stack gap='xl'>
          <Text>Store: {data.store.name}</Text>
          <Text>Stock editor placeholder</Text>
        </Stack>
      </Stack>
    </>
  )
}
