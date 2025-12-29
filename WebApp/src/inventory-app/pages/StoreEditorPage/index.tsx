import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router'
import { useMutation } from '@tanstack/react-query'
import { Anchor, Button, Group, Loader, Stack, Text, Title } from '@mantine/core'
import { IconArrowBackUp, IconChevronLeft } from '@tabler/icons-react'

import { useApi, usePath } from 'src/app/contexts'
import { InvStore } from 'src/inventory-app/models/InvStore'
import { CatalogEditor } from './CatalogEditor'
import formatError from 'src/common/format-error'
import useModal from 'src/utils/use-modal'
import { ConfirmModal } from 'src/utils/ConfirmModal'
import { Dispatch, ValueOrReducer } from 'src/utils/types-lib'

export default function StoreEditorPage() {
  const { storeId } = useParams()
  const { navigate } = usePath()
  const { axios } = useApi()
  // const storeName = location.state?.storeName

  const [initialStore, setInitialStore] = useState<InvStore | null>(null)
  const [store, setStore] = useState<InvStore | null>(null)
  const [saveTrigger, setSaveTrigger] = useState(0)
  const [dirty, setDirty] = useState(false)

  // Load

  const { mutate: loadStore, error: loadError, isPending: isLoading } = useMutation({
    mutationFn: async () => {
      return (await axios.get<InvStore>(`store/${storeId}`)).data
    },
    onSuccess: store => {
      setInitialStore(store)
      setStore(store)
    }
  })

  useEffect(() => {
    loadStore()
  }, [loadStore])

  // Save

  const { mutate: saveStore, error: saveError, isPending: isSaving } = useMutation({
    mutationFn: async (store: InvStore) => {
      const body = store.catalog
      await axios.put(`store/${storeId}/catalog`, body)
    }
  })

  useEffect(() => {
    if (saveTrigger > 0) {
      saveStore(store!)
    }
  }, [store, saveStore, saveTrigger])

  const setNeedsSave = useCallback(() => {
    setSaveTrigger(x => x + 1)
  }, [setSaveTrigger])

  // Set

  const setStoreAndSave: Dispatch<ValueOrReducer<InvStore | null>> = useCallback(valueOrReducer => {
    setStore(valueOrReducer)
    setNeedsSave()
    setDirty(true)
  }, [setStore, setNeedsSave])

  const revertStoreAndSave = useCallback(() => {
    setStore(initialStore)
    setNeedsSave()
    setDirty(false)
  }, [initialStore, setStore, setNeedsSave])

  return (
    <Stack align='flex-start' gap='lg'>
      {/* Save error */}
      {
        saveError &&
        <Stack align='center'>
          <Group>
            <Text c='red'>{formatError(saveError)}</Text>
            {/* <Button variant='subtle' size='compact-md'>Retry</Button> */}
            <Anchor href='#' onClick={() => saveStore(store!)}>Retry</Anchor>
          </Group>
        </Stack>
      }

      {/* Back link */}
      <Anchor size='sm' href='#' onClick={() => navigate(`/`)}>
        <Group gap='0.2rem'>
          <IconChevronLeft size={18} />
          Back to Inventory
        </Group>
      </Anchor>

      {/* Content */}
      {(() => {
        if (isLoading) {
          return <Text>Loading...</Text>
        }

        if (loadError) {
          return <Text c='red'>{formatError(loadError)}</Text>
        }

        if (!store) {
          return <>???</>
        }

        return (
          <>
            <title>{store.name + ' | The Duck Group'}</title>
            <MetaAndContent
              store={store}
              setStore={setStoreAndSave}
              revertStore={revertStoreAndSave}
              saving={isSaving}
              dirty={dirty}
            />
          </>
        )
      })()}
    </Stack >
  )
}

/**
 * Store meta (name etc) and content (items and sections).
 */
function MetaAndContent({ store, setStore, revertStore, saving, dirty }: {
  store: InvStore
  setStore: Dispatch<ValueOrReducer<InvStore | null>>,
  revertStore: () => void
  saving: boolean
  dirty: boolean
}) {
  const confirmModal = useModal(ConfirmModal)

  function handleRevert() {
    confirmModal.open({
      title: 'Revert changes?',
      message: 'Data will be reverted back to the state when you visited this page (before any changes were made).',
      actions: [
        {
          label: 'Revert',
          role: 'destructive',
          handler: revertStore
        }
      ]
    })
  }

  type Reducer<T> = (prev: T) => T

  const setData: Dispatch<Reducer<[InvStore.Item[], InvStore.Section[]]>> = reducer => {
    setStore(store => {
      const [items, sections] = reducer([store!.catalog.items, store!.catalog.sections])
      return { ...store!, catalog: { items, sections } }
    })
  }

  return (
    <Stack className='w-full' gap='xl'>
      {/* Metadata + Save loader */}
      <Group className='w-full items-start'>
        {/* Metadata + Edit button */}
        {/* <Stack w='100%' gap='xs' align='flex-start' mr='auto'> */}
        <Stack className='w-full gap-2 items-start mr-auto'>
          {/* Title + Edit button + Saving loader + Reset button */}
          <Group bg='dark.9' pt='sm' className='gap-2 items-baseline'>
            {/* Name */}
            <Title order={1} c='gray.1'>Edit Items</Title>
            {/* Edit button */}
            {/* <Button variant='light' size='compact-xs' fw='normal' onClick={handleEdit}>
              <Group gap='0.25rem'>
                <IconPencil size={13} />
                Edit
              </Group>
            </Button> */}
            {/* Save loader */}
            {saving && <Loader ml='auto' size='xs' />}
            {/* Revert button */}
            {(dirty && !saving) &&
              <Button ml='auto' variant='light' size='compact-sm' fw='normal' onClick={handleRevert}>
                <Group gap='0.35rem'>
                  <IconArrowBackUp size={15} />
                  Revert
                </Group>
              </Button>
            }
          </Group>
          {/* Code, items per page */}
          {/* <Stack gap='0'>
            <Text>Code: {template.code}</Text>
            <Text>Email Recipients: {template.emailRecipients.join(', ')}</Text>
          </Stack> */}
        </Stack>
      </Group>

      {/* Items editor */}
      <CatalogEditor
        items={store.catalog.items}
        sections={store.catalog.sections}
        setData={setData}
      />

      {/* Modals */}
      {confirmModal.element}

    </Stack>
  )
}